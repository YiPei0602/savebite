/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#00615F',
          dark: '#004D40',
          light: '#4DB6AC',
        },
        accent: {
          DEFAULT: '#FF6B00',
          dark: '#E65100',
        },
        background: {
          DEFAULT: '#F9F3F0',
          paper: '#FFFFFF',
        },
      },
    },
  },
  plugins: [],
}

