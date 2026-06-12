"use client";

import {
  createContext,
  useContext,
  useState,
  useEffect,
  type ReactNode,
} from "react";
import { createClient } from "@/lib/supabase/client";
import type { Organization, MembershipWithOrg, MemberRole } from "@/types/database";

interface OrgContextValue {
  orgs: Organization[];
  currentOrg: Organization | null;
  currentRole: MemberRole | null;
  switchOrg: (orgId: string) => void;
  loading: boolean;
}

const OrgContext = createContext<OrgContextValue>({
  orgs: [],
  currentOrg: null,
  currentRole: null,
  switchOrg: () => {},
  loading: true,
});

export function OrgProvider({ children }: { children: ReactNode }) {
  const [memberships, setMemberships] = useState<MembershipWithOrg[]>([]);
  const [currentOrgId, setCurrentOrgId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const supabase = createClient();

  useEffect(() => {
    async function loadOrgs() {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        setLoading(false);
        return;
      }

      const { data } = await supabase
        .from("memberships")
        .select("*, organizations(*)")
        .eq("user_id", user.id);

      if (data && data.length > 0) {
        setMemberships(data as unknown as MembershipWithOrg[]);
        const stored = localStorage.getItem("leadlatch_org_id");
        const validStored = data.find(
          (m: { org_id: string }) => m.org_id === stored
        );
        setCurrentOrgId(validStored ? stored : data[0].org_id);
      }
      setLoading(false);
    }
    loadOrgs();
  }, [supabase]);

  const switchOrg = (orgId: string) => {
    setCurrentOrgId(orgId);
    localStorage.setItem("leadlatch_org_id", orgId);
  };

  const orgs = memberships.map((m) => m.organizations);
  const currentMembership = memberships.find((m) => m.org_id === currentOrgId);
  const currentOrg = currentMembership?.organizations ?? null;
  const currentRole = currentMembership?.role ?? null;

  return (
    <OrgContext.Provider
      value={{ orgs, currentOrg, currentRole, switchOrg, loading }}
    >
      {children}
    </OrgContext.Provider>
  );
}

export function useOrg() {
  return useContext(OrgContext);
}
