"use client";

import { useOrg } from "@/lib/org-context";

export function OrgSwitcher() {
  const { orgs, currentOrg, switchOrg } = useOrg();

  if (orgs.length === 0) {
    return (
      <p className="text-xs text-gray-400">No organization</p>
    );
  }

  if (orgs.length === 1) {
    return (
      <p className="truncate text-sm font-medium">{currentOrg?.name}</p>
    );
  }

  return (
    <select
      value={currentOrg?.id ?? ""}
      onChange={(e) => switchOrg(e.target.value)}
      className="w-full rounded-md border border-gray-300 bg-white px-2 py-1.5 text-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
    >
      {orgs.map((org) => (
        <option key={org.id} value={org.id}>
          {org.name}
        </option>
      ))}
    </select>
  );
}
