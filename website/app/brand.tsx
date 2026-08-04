import Image from "next/image";
import Link from "next/link";

type BrandProps = {
  ariaLabel?: string;
  href?: string;
  size?: number;
};

export function Brand({
  ariaLabel = "OneSend 首页",
  href = "/",
  size = 42,
}: BrandProps) {
  const content = (
    <>
      <Image
        className="brand-icon"
        src="/icon.png"
        alt=""
        aria-hidden="true"
        width={size}
        height={size}
        unoptimized
      />
      <span>OneSend</span>
    </>
  );

  if (href.startsWith("#")) {
    return (
      <a className="brand" href={href} aria-label={ariaLabel}>
        {content}
      </a>
    );
  }

  return (
    <Link className="brand" href={href} aria-label={ariaLabel}>
      {content}
    </Link>
  );
}
