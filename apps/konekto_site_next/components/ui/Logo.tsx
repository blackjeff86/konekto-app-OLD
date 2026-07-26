import Link from "next/link";

type Props = {
  className?: string;
};

export function Logo({ className }: Props) {
  return (
    <Link href="/" className={`inline-flex items-center no-underline ${className ?? ""}`}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/logo/icon-and-wordmark.svg" alt="Sevvn" className="h-[38px] w-auto" />
    </Link>
  );
}
