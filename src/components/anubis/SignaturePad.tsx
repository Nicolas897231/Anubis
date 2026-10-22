"use client";

import { useEffect, useRef, useState } from "react";
import { Input } from "@/components/ui/input";
import { FormField } from "./FormField";

const canvasWidth = 640;
const canvasHeight = 220;

export function SignaturePad() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const drawing = useRef(false);
  const [hasInk, setHasInk] = useState(false);

  function point(event: React.PointerEvent<HTMLCanvasElement>) {
    const canvas = canvasRef.current;
    if (!canvas) return null;
    const rect = canvas.getBoundingClientRect();
    return {
      x: ((event.clientX - rect.left) / rect.width) * canvas.width,
      y: ((event.clientY - rect.top) / rect.height) * canvas.height,
    };
  }
  function start(event: React.PointerEvent<HTMLCanvasElement>) {
    const canvas = canvasRef.current;
    const p = point(event);
    if (!canvas || !p) return;
    canvas.setPointerCapture(event.pointerId);
    const context = canvas.getContext("2d");
    if (!context) return;
    context.beginPath();
    context.moveTo(p.x, p.y);
    drawing.current = true;
  }
  function move(event: React.PointerEvent<HTMLCanvasElement>) {
    if (!drawing.current) return;
    const p = point(event);
    const context = canvasRef.current?.getContext("2d");
    if (!p || !context) return;
    context.lineTo(p.x, p.y);
    context.stroke();
    setHasInk(true);
  }
  function stop() {
    drawing.current = false;
  }
  function clear() {
    const canvas = canvasRef.current;
    const context = canvas?.getContext("2d");
    if (canvas && context) context.clearRect(0, 0, canvas.width, canvas.height);
    setHasInk(false);
  }
  function prepare(form: HTMLFormElement) {
    const canvas = canvasRef.current;
    const output = form.elements.namedItem("signature_data");
    const written = form.elements.namedItem("written_signature") as HTMLInputElement | null;
    if (canvas && output instanceof HTMLInputElement && !hasInk && written?.value.trim()) {
      const context = canvas.getContext("2d");
      if (context) {
        context.font = "32px sans-serif";
        context.fillText(written.value.trim(), 24, 120);
      }
    }
    if (canvas && output instanceof HTMLInputElement) output.value = canvas.toDataURL("image/png");
  }
  useEffect(() => {
    const form = canvasRef.current?.closest("form");
    if (!form) return;
    const onSubmit = () => prepare(form);
    form.addEventListener("submit", onSubmit);
    return () => form.removeEventListener("submit", onSubmit);
  });
  return (
    <div className="space-y-4">
      <div>
        <p className="text-sm font-medium">Firma del cliente</p>
        <p className="text-sm text-muted-foreground">Dibuja con el dedo, mouse o lapiz.</p>
      </div>
      <canvas
        ref={canvasRef}
        width={canvasWidth}
        height={canvasHeight}
        aria-label="Lienzo para firma"
        className="h-auto w-full touch-none rounded-md border border-input bg-white"
        onPointerDown={start}
        onPointerMove={move}
        onPointerUp={stop}
        onPointerCancel={stop}
      />
      <button type="button" className="text-sm underline" onClick={clear}>Limpiar firma</button>
      <FormField id="written_signature" label="Alternativa escrita (accesible)">
        <Input id="written_signature" name="written_signature" maxLength={120} />
      </FormField>
      <input type="hidden" name="signature_data" defaultValue="" />
      <p className="text-xs text-muted-foreground">Si usas la alternativa escrita, se conservara como imagen de constancia.</p>
      <input type="hidden" name="accepted" value="yes" />
      <input type="hidden" name="consent_version" value="receipt-v1" />
    </div>
  );
}
