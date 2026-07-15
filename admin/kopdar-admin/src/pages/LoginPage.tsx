import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/hooks/useAuth";
import toast from "react-hot-toast";

export default function LoginPage() {
  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  const [step, setStep] = useState<"phone" | "otp">("phone");
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [loading, setLoading] = useState(false);

  // Redirect if already logged in
  if (isAuthenticated) {
    navigate("/", { replace: true });
    return null;
  }

  const handleSendOtp = (e: React.FormEvent) => {
    e.preventDefault();
    if (!phone.trim()) {
      toast.error("Masukkan nomor telepon");
      return;
    }
    // Mock: just move to OTP step
    toast.success("Kode OTP telah dikirim!");
    setStep("otp");
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otp.trim()) {
      toast.error("Masukkan kode OTP");
      return;
    }

    setLoading(true);
    const success = await login(phone, otp);
    setLoading(false);

    if (success) {
      toast.success("Selamat datang!");
      navigate("/", { replace: true });
    } else {
      toast.error("Kode OTP salah. Gunakan 123456 untuk demo.");
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-primary-50 to-primary-100 p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary shadow-lg shadow-primary/30">
            <svg className="h-8 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">KopDar Admin</h1>
          <p className="mt-1 text-sm text-gray-500">Masuk ke panel administrasi</p>
        </div>

        {/* Card */}
        <div className="card p-6">
          {step === "phone" ? (
            <form onSubmit={handleSendOtp}>
              <h2 className="text-lg font-semibold text-gray-900">Masuk</h2>
              <p className="mt-1 text-sm text-gray-500">Masukkan nomor telepon Anda</p>

              <div className="mt-6">
                <label htmlFor="phone" className="mb-1.5 block text-sm font-medium text-gray-700">
                  Nomor Telepon
                </label>
                <input
                  id="phone"
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="081234567890"
                  className="input"
                  autoComplete="tel"
                />
              </div>

              <button type="submit" className="btn btn-primary mt-6 w-full">
                Kirim Kode OTP
              </button>

              <p className="mt-4 text-center text-xs text-gray-400">
                Demo: masukkan nomor apapun, lalu gunakan OTP <span className="font-mono font-semibold">123456</span>
              </p>
            </form>
          ) : (
            <form onSubmit={handleLogin}>
              <h2 className="text-lg font-semibold text-gray-900">Verifikasi OTP</h2>
              <p className="mt-1 text-sm text-gray-500">
                Kode OTP telah dikirim ke <span className="font-medium text-gray-700">{phone}</span>
              </p>

              <div className="mt-6">
                <label htmlFor="otp" className="mb-1.5 block text-sm font-medium text-gray-700">
                  Kode OTP
                </label>
                <input
                  id="otp"
                  type="text"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
                  placeholder="123456"
                  className="input text-center font-mono text-lg tracking-widest"
                  maxLength={6}
                  autoComplete="one-time-code"
                />
              </div>

              <button type="submit" disabled={loading} className="btn btn-primary mt-6 w-full">
                {loading ? (
                  <span className="flex items-center gap-2">
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                    Memverifikasi...
                  </span>
                ) : (
                  "Masuk"
                )}
              </button>

              <button
                type="button"
                onClick={() => {
                  setStep("phone");
                  setOtp("");
                }}
                className="btn btn-ghost mt-3 w-full"
              >
                Ganti Nomor
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
