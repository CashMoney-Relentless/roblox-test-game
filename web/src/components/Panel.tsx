import type { ReactNode } from "react";

interface Props {
  title: string;
  subtitle?: string;
  right?: ReactNode;
  children: ReactNode;
  className?: string;
}

export function Panel({ title, subtitle, right, children, className = "" }: Props) {
  return (
    <section className={`panel ${className}`}>
      <header className="panel-header">
        <span className="flex items-center gap-2">
          <span className="led led-on-amber" />
          {title}
          {subtitle && <span className="text-panel-400/70 normal-case tracking-normal">— {subtitle}</span>}
        </span>
        {right}
      </header>
      <div className="p-3">{children}</div>
    </section>
  );
}
