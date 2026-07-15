import clsx from "clsx";

interface LoadingSpinnerProps {
  size?: "sm" | "md" | "lg";
  className?: string;
}

const sizeClasses = {
  sm: "h-5 w-5 border-2",
  md: "h-8 w-8 border-3",
  lg: "h-12 w-12 border-4",
};

export default function LoadingSpinner({ size = "md", className }: LoadingSpinnerProps) {
  return (
    <div className={clsx("flex items-center justify-center", className)}>
      <div
        className={clsx(
          "animate-spin rounded-full border-primary/30 border-t-primary",
          sizeClasses[size]
        )}
      />
    </div>
  );
}
