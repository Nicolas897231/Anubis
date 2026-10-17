"use client";
import { useState } from "react";
import { Input } from "@/components/ui/input";

export function DateTimeField({
  name,
  label,
}: {
  name: string;
  label: string;
}) {
  const [value, setValue] = useState("");
  const date = value ? new Date(value) : null;
  return (
    <label className="block space-y-2 text-sm font-medium">
      <span>{label} (hora de este dispositivo)</span>
      <Input
        type="datetime-local"
        value={value}
        onChange={(event) => setValue(event.target.value)}
      />
      <input
        type="hidden"
        name={name}
        value={
          date && Number.isFinite(date.getTime()) ? date.toISOString() : ""
        }
      />
    </label>
  );
}
