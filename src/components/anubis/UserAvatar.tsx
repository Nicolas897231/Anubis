import { cn } from "@/lib/utils";

export function UserAvatar({
  name,
  className,
}: {
  name: string;
  className?: string;
}) {
  const initials = name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");

  return (
    <div
      className={cn(
        "inline-flex size-10 items-center justify-center rounded-full bg-accent-soft text-sm font-semibold text-accent-strong",
        className,
      )}
      aria-label={name}
    >
      {initials || "A"}
    </div>
  );
}
