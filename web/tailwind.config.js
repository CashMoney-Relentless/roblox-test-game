/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        panel: {
          950: "#070a0d",
          900: "#0c1116",
          800: "#151c24",
          700: "#1d2731",
          600: "#26333f",
          500: "#34424f",
          400: "#4b5d6c",
        },
        readout: {
          green: "#34ff7a",
          amber: "#ffb030",
          red: "#ff3838",
          blue: "#3ad6ff",
          dim: "#1a3320",
        },
      },
      fontFamily: {
        mono: ["JetBrains Mono", "ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
        display: ["Rajdhani", "Inter", "sans-serif"],
      },
      boxShadow: {
        bezel:
          "inset 0 1px 0 rgba(255,255,255,0.08), inset 0 -2px 0 rgba(0,0,0,0.5), 0 1px 0 rgba(0,0,0,0.6)",
        glow: "0 0 14px rgba(52,255,122,0.45)",
        glowAmber: "0 0 14px rgba(255,176,48,0.5)",
        glowRed: "0 0 14px rgba(255,56,56,0.55)",
      },
      keyframes: {
        flash: {
          "0%, 49%": { opacity: "1" },
          "50%, 100%": { opacity: "0.25" },
        },
        scan: {
          "0%": { transform: "translateY(-100%)" },
          "100%": { transform: "translateY(100%)" },
        },
      },
      animation: {
        flash: "flash 0.85s steps(2) infinite",
        scan: "scan 8s linear infinite",
      },
    },
  },
  plugins: [],
};
