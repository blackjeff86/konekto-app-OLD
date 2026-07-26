const CURRENT_YEAR = new Date().getFullYear();

export function SiteFooter() {
  return (
    <footer className="border-t border-border py-10">
      <div className="mx-auto grid max-w-[1180px] grid-cols-1 items-center gap-6 px-8 sm:grid-cols-3">
        <span className="text-[13px] text-muted">© {CURRENT_YEAR} Sevvn, Guest Experience Platform</span>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo/sevvn-lockup-footer.svg" alt="Sevvn" className="mx-auto h-14 w-auto" />
        <div className="flex items-center gap-6 sm:justify-end">
          <a href="mailto:contato@sevvn.app" className="text-[13px] text-muted no-underline">
            contato@sevvn.app
          </a>
          <a href="https://konektoadmin.vercel.app" className="text-[13px] text-muted no-underline">
            Acesso admin
          </a>
        </div>
      </div>
    </footer>
  );
}
