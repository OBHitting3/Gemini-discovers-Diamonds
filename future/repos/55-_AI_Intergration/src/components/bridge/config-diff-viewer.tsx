"use client";

interface ConfigDiffViewerProps {
  before: string;
  after: string;
  title?: string;
}

interface DiffLine {
  type: "added" | "removed" | "unchanged";
  content: string;
  lineNumber: number;
}

function computeDiff(before: string, after: string): DiffLine[] {
  const beforeLines = before.split("\n");
  const afterLines = after.split("\n");

  // Simple line-by-line diff
  const result: DiffLine[] = [];
  const maxLen = Math.max(beforeLines.length, afterLines.length);

  for (let i = 0; i < maxLen; i++) {
    const bLine = beforeLines[i];
    const aLine = afterLines[i];

    if (bLine === undefined) {
      result.push({ type: "added", content: aLine, lineNumber: i + 1 });
    } else if (aLine === undefined) {
      result.push({ type: "removed", content: bLine, lineNumber: i + 1 });
    } else if (bLine !== aLine) {
      result.push({ type: "removed", content: bLine, lineNumber: i + 1 });
      result.push({ type: "added", content: aLine, lineNumber: i + 1 });
    } else {
      result.push({ type: "unchanged", content: bLine, lineNumber: i + 1 });
    }
  }

  return result;
}

export default function ConfigDiffViewer({
  before,
  after,
  title,
}: ConfigDiffViewerProps) {
  const diffLines = computeDiff(before, after);
  const hasChanges = diffLines.some((l) => l.type !== "unchanged");

  return (
    <div className="border border-gray-700 rounded overflow-hidden">
      {title && (
        <div className="bg-gray-900 border-b border-gray-700 px-4 py-2 text-sm font-semibold text-gray-300">
          {title}
        </div>
      )}

      <div className="grid grid-cols-2 gap-0">
        {/* Before column */}
        <div className="border-r border-gray-700">
          <div className="bg-gray-900 px-3 py-1.5 text-xs text-gray-400 border-b border-gray-700">
            Before
          </div>
          <pre className="p-3 text-xs overflow-x-auto text-gray-300 font-mono leading-relaxed">
            {diffLines
              .filter((l) => l.type !== "added")
              .map((line, idx) => (
                <div
                  key={idx}
                  className={`${
                    line.type === "removed"
                      ? "bg-red-900/40 text-red-300"
                      : "text-gray-400"
                  } px-1`}
                >
                  <span className="select-none text-gray-600 mr-3">
                    {String(line.lineNumber).padStart(4, " ")}
                  </span>
                  {line.content}
                </div>
              ))}
          </pre>
        </div>

        {/* After column */}
        <div>
          <div className="bg-gray-900 px-3 py-1.5 text-xs text-gray-400 border-b border-gray-700">
            After
          </div>
          <pre className="p-3 text-xs overflow-x-auto text-gray-300 font-mono leading-relaxed">
            {diffLines
              .filter((l) => l.type !== "removed")
              .map((line, idx) => (
                <div
                  key={idx}
                  className={`${
                    line.type === "added"
                      ? "bg-green-900/40 text-green-300"
                      : "text-gray-400"
                  } px-1`}
                >
                  <span className="select-none text-gray-600 mr-3">
                    {String(line.lineNumber).padStart(4, " ")}
                  </span>
                  {line.content}
                </div>
              ))}
          </pre>
        </div>
      </div>

      {!hasChanges && (
        <div className="text-center text-xs text-gray-500 py-3 border-t border-gray-700">
          No changes detected
        </div>
      )}
    </div>
  );
}
