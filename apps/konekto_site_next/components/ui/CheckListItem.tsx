type Props = {
  children: React.ReactNode;
};

export function CheckListItem({ children }: Props) {
  return (
    <li className="flex items-start gap-[0.7rem] text-[0.95rem]">
      <span className="mt-[0.15rem] flex h-5 w-5 flex-none items-center justify-center rounded-full bg-primary-soft text-[0.68rem] font-bold text-primary-text">
        ✓
      </span>
      <span>{children}</span>
    </li>
  );
}
