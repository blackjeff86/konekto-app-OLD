import type { CSSProperties, ReactNode } from "react";

export type AuraBottomNavItem = {
  id: string;
  label: string;
  icon: string;
};

export function AuraShell({
  children,
  footer,
  style,
  topBar,
}: {
  children: ReactNode;
  footer?: ReactNode;
  style?: CSSProperties;
  topBar?: ReactNode;
}) {
  return (
    <main className="guest-stage" style={style}>
      <div className="aura-mobile-shell">
        <section className="guest-panel aura-shell-surface">
          {topBar}
          <div className="aura-shell-body">{children}</div>
          {footer ? <div className="aura-shell-footer">{footer}</div> : null}
        </section>
      </div>
    </main>
  );
}

export function AuraTopBar({
  action,
  eyebrow,
  leading,
  subtitle,
  title,
}: {
  action?: ReactNode;
  eyebrow?: string;
  leading?: ReactNode;
  subtitle?: string;
  title: string;
}) {
  return (
    <header className="aura-shell-header">
      <div className="aura-shell-header-main">
        <div className="aura-avatar">
          {leading ?? (
            <span className="material-symbols-outlined" aria-hidden="true">
              person
            </span>
          )}
        </div>
        <div>
          {eyebrow ? <p className="guest-eyebrow">{eyebrow}</p> : null}
          <h1 className="aura-header-title">{title}</h1>
          {subtitle ? <p className="aura-header-subtitle">{subtitle}</p> : null}
        </div>
      </div>
      {action}
    </header>
  );
}

export function AuraIconButton({
  icon,
  label,
  onClick,
}: {
  icon: string;
  label: string;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      className="aura-icon-button"
      aria-label={label}
      onClick={onClick}
    >
      <span className="material-symbols-outlined" aria-hidden="true">
        {icon}
      </span>
    </button>
  );
}

export function AuraBottomNav({
  activeId,
  items,
  onSelect,
}: {
  activeId: string;
  items: AuraBottomNavItem[];
  onSelect: (itemId: string) => void;
}) {
  return (
    <nav className="aura-bottom-nav" aria-label="Navegacao do hospede">
      {items.map((item) => {
        const isActive = item.id === activeId;
        return (
          <button
            key={item.id}
            type="button"
            className={`aura-bottom-nav-button${
              isActive ? " aura-bottom-nav-button-active" : ""
            }`}
            onClick={() => onSelect(item.id)}
          >
            <span className="material-symbols-outlined" aria-hidden="true">
              {item.icon}
            </span>
            <span className="aura-bottom-nav-label">{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
}

export function AuraCard({
  children,
  className = "",
  soft = false,
}: {
  children: ReactNode;
  className?: string;
  soft?: boolean;
}) {
  return (
    <article
      className={`aura-surface-card${soft ? " aura-surface-card-soft" : ""}${
        className ? ` ${className}` : ""
      }`}
    >
      {children}
    </article>
  );
}

export function AuraSectionHeading({
  copy,
  title,
  trailing,
}: {
  copy?: string;
  title: string;
  trailing?: ReactNode;
}) {
  return (
    <div className="aura-section-heading">
      <div>
        <h2 className="aura-section-title">{title}</h2>
        {copy ? <p className="aura-section-copy">{copy}</p> : null}
      </div>
      {trailing}
    </div>
  );
}
