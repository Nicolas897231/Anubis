import Image from "next/image";

import { cn } from "@/lib/utils";

const markSrc = "/brand/anubis-app-icon.png";
const lightLockupSrc = "/brand/anubis-light-lockup.png";
const darkLockupSrc = "/brand/anubis-dark-lockup.png";

export function AnubisMark({
  size = "md",
  className,
}: {
  size?: "sm" | "md" | "lg" | "xl";
  className?: string;
}) {
  const dimensions = {
    sm: 32,
    md: 44,
    lg: 64,
    xl: 96,
  }[size];

  return (
    <Image
      alt="Isotipo ANUBIS"
      className={cn(
        "shrink-0 rounded-[18%] object-cover shadow-[0_2px_8px_rgba(11,13,13,0.18)]",
        className,
      )}
      height={dimensions}
      src={markSrc}
      width={dimensions}
    />
  );
}

export function AnubisLogo({
  className,
  priority = false,
  tone = "light",
}: {
  className?: string;
  priority?: boolean;
  tone?: "light" | "dark";
}) {
  return (
    <Image
      alt="ANUBIS by S&N TI"
      className={cn("h-auto w-full object-contain", className)}
      height={1402}
      preload={priority}
      src={tone === "dark" ? darkLockupSrc : lightLockupSrc}
      width={1122}
    />
  );
}

export function PoweredBySN({ className }: { className?: string }) {
  return (
    <span
      className={cn("text-xs font-medium text-muted-foreground", className)}
    >
      by S&amp;N TI
    </span>
  );
}

export function BrandDivider({ className }: { className?: string }) {
  return (
    <span
      aria-hidden="true"
      className={cn("block h-px w-14 bg-accent", className)}
    />
  );
}

export function BrandLockup({
  compact = false,
  className,
  inverse = false,
}: {
  compact?: boolean;
  className?: string;
  inverse?: boolean;
}) {
  return (
    <div className={cn("flex items-center gap-3", className)}>
      <AnubisMark size={compact ? "sm" : "md"} />
      <div className="min-w-0">
        <p
          className={cn(
            "text-sm font-semibold tracking-[0.22em]",
            inverse ? "text-white" : "text-foreground",
          )}
        >
          ANUBIS
        </p>
        <div className="mt-1 flex items-center gap-2">
          <BrandDivider className={inverse ? "bg-accent" : undefined} />
          <PoweredBySN
            className={inverse ? "text-white/70" : "text-muted-foreground"}
          />
        </div>
      </div>
    </div>
  );
}
