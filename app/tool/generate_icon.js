// Genera assets/icon/icon.png — ícono moderno de cumpleaños
// Ejecutar desde la carpeta app/: node tool/generate_icon.js
const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

const SIZE = 1024;
const buf = new Uint8ClampedArray(SIZE * SIZE * 4);

// ── Helpers ──────────────────────────────────────────────────

function setPixel(x, y, r, g, b, a = 255) {
  if (x < 0 || x >= SIZE || y < 0 || y >= SIZE) return;
  const i = (~~y * SIZE + ~~x) * 4;
  const alpha = a / 255;
  buf[i]     = Math.round(buf[i]     * (1 - alpha) + r * alpha);
  buf[i + 1] = Math.round(buf[i + 1] * (1 - alpha) + g * alpha);
  buf[i + 2] = Math.round(buf[i + 2] * (1 - alpha) + b * alpha);
  buf[i + 3] = Math.min(255, buf[i + 3] + Math.round(alpha * 255));
}

function fillCircle(cx, cy, radius, r, g, b, a = 255) {
  const x0 = Math.floor(cx - radius - 1), x1 = Math.ceil(cx + radius + 1);
  const y0 = Math.floor(cy - radius - 1), y1 = Math.ceil(cy + radius + 1);
  for (let y = y0; y <= y1; y++) {
    for (let x = x0; x <= x1; x++) {
      const dist = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2);
      const alpha = Math.max(0, Math.min(1, radius - dist + 0.5));
      if (alpha > 0) setPixel(x, y, r, g, b, Math.round(a * alpha));
    }
  }
}

function fillRect(x1, y1, x2, y2, r, g, b, a = 255) {
  for (let y = y1; y <= y2; y++)
    for (let x = x1; x <= x2; x++)
      setPixel(x, y, r, g, b, a);
}

function fillRoundedRect(x1, y1, x2, y2, rad, r, g, b, a = 255) {
  const corners = [
    [x1 + rad, y1 + rad],
    [x2 - rad, y1 + rad],
    [x1 + rad, y2 - rad],
    [x2 - rad, y2 - rad],
  ];
  for (let y = Math.floor(y1 - 1); y <= Math.ceil(y2 + 1); y++) {
    for (let x = Math.floor(x1 - 1); x <= Math.ceil(x2 + 1); x++) {
      let alpha = 0;
      if (x >= x1 + rad && x <= x2 - rad && y >= y1 && y <= y2) {
        alpha = 1;
      } else if (y >= y1 + rad && y <= y2 - rad && x >= x1 && x <= x2) {
        alpha = 1;
      } else {
        const cx2 = x < x1 + rad ? x1 + rad : x2 - rad;
        const cy2 = y < y1 + rad ? y1 + rad : y2 - rad;
        if (x >= x1 && x <= x2 && y >= y1 && y <= y2) {
          const dist = Math.sqrt((x - cx2) ** 2 + (y - cy2) ** 2);
          alpha = Math.max(0, Math.min(1, rad - dist + 0.5));
        }
      }
      if (alpha > 0) setPixel(x, y, r, g, b, Math.round(a * alpha));
    }
  }
}

// ── Gradient background ───────────────────────────────────────
// Top-left: #6366F1 (indigo), bottom-right: #1D4ED8 (blue-700)
for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    const t = (x + y) / (2 * (SIZE - 1));
    const r = Math.round(99  + (29  - 99)  * t);
    const g = Math.round(102 + (78  - 102) * t);
    const b = Math.round(241 + (216 - 241) * t);
    const i = (y * SIZE + x) * 4;
    buf[i] = r; buf[i+1] = g; buf[i+2] = b; buf[i+3] = 255;
  }
}

const cx = SIZE / 2;
const cy = SIZE / 2;

// ── White soft glow behind card ───────────────────────────────
fillCircle(cx, cy, 390, 255, 255, 255, 18);
fillCircle(cx, cy, 340, 255, 255, 255, 18);

// ── White card ────────────────────────────────────────────────
fillRoundedRect(cx - 290, cy - 290, cx + 290, cy + 290, 72, 255, 255, 255, 230);

// Icon color: indigo #6366F1
const [IR, IG, IB] = [99, 102, 241];

// ── Cake bottom tier ──────────────────────────────────────────
fillRoundedRect(cx - 190, cy + 60, cx + 190, cy + 210, 28, IR, IG, IB, 255);

// Frosting drips on bottom tier (white bumps on top edge)
for (let i = -2; i <= 2; i++) {
  fillCircle(cx + i * 78, cy + 60, 22, 255, 255, 255, 220);
}

// ── Cake top tier ─────────────────────────────────────────────
fillRoundedRect(cx - 120, cy - 60, cx + 120, cy + 80, 22, IR, IG, IB, 220);

// Frosting drips on top tier
for (let i = -1; i <= 1; i++) {
  fillCircle(cx + i * 100, cy - 60, 18, 255, 255, 255, 200);
}

// ── Candles (3) ──────────────────────────────────────────────
const candleX = [-90, 0, 90];
candleX.forEach(ox => {
  // Candle body (white)
  fillRoundedRect(cx + ox - 11, cy - 165, cx + ox + 11, cy - 62, 8, 255, 255, 255, 240);
  // Candle stripe (indigo)
  fillRect(cx + ox - 11, cy - 140, cx + ox + 11, cy - 125, IR, IG, IB, 200);
  // Flame outer (amber #FCD34D)
  fillCircle(cx + ox, cy - 182, 19, 252, 211, 77, 255);
  // Flame inner (orange-red #FB923C)
  fillCircle(cx + ox, cy - 178, 11, 251, 146, 60, 240);
  // Flame core (white)
  fillCircle(cx + ox, cy - 175, 5, 255, 255, 255, 200);
});

// ── Confetti dots ─────────────────────────────────────────────
const dots = [
  { x: -230, y: -220, r: 18, c: [252, 211, 77]  },  // amber
  { x:  230, y: -200, r: 14, c: [52,  211, 153] },   // emerald
  { x: -210, y:  210, r: 16, c: [251, 146, 60]  },   // orange
  { x:  220, y:  210, r: 12, c: [167, 139, 250] },   // violet
  { x: -260, y:   10, r: 10, c: [252, 211, 77]  },
  { x:  260, y:   20, r: 10, c: [52,  211, 153] },
  { x:    0, y: -240, r: 12, c: [251, 146, 60]  },
];
dots.forEach(({ x, y, r, c }) => {
  fillCircle(cx + x, cy + y, r, ...c, 230);
});

// ── Star sparkles ─────────────────────────────────────────────
function drawStar(sx, sy, outerR, innerR, color) {
  const [r, g, b] = color;
  const points = 4;
  // Draw as two overlapping rects rotated (simple cross)
  fillRoundedRect(sx - outerR, sy - innerR * 0.4, sx + outerR, sy + innerR * 0.4,
                  innerR * 0.3, r, g, b, 220);
  fillRoundedRect(sx - innerR * 0.4, sy - outerR, sx + innerR * 0.4, sy + outerR,
                  innerR * 0.3, r, g, b, 220);
  fillCircle(sx, sy, innerR * 0.5, 255, 255, 255, 200);
}
drawStar(cx - 240, cy - 230, 22, 10, [252, 211, 77]);
drawStar(cx + 235, cy - 215, 18,  8, [167, 139, 250]);
drawStar(cx - 225, cy + 220, 16,  7, [52,  211, 153]);
drawStar(cx + 225, cy + 220, 20,  9, [252, 211, 77]);

// ── PNG encoder ───────────────────────────────────────────────
function crc32(data) {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    table[n] = c;
  }
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < data.length; i++)
    crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function chunk(type, data) {
  const t = Buffer.from(type);
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const crcVal = Buffer.alloc(4);
  crcVal.writeUInt32BE(crc32(Buffer.concat([t, data])));
  return Buffer.concat([len, t, data, crcVal]);
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);
ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8; ihdr[9] = 6; // RGBA

const raw = Buffer.alloc(SIZE * (1 + SIZE * 4));
for (let y = 0; y < SIZE; y++) {
  raw[y * (1 + SIZE * 4)] = 0;
  for (let x = 0; x < SIZE; x++) {
    const si = (y * SIZE + x) * 4;
    const di = y * (1 + SIZE * 4) + 1 + x * 4;
    raw[di] = buf[si]; raw[di+1] = buf[si+1]; raw[di+2] = buf[si+2]; raw[di+3] = buf[si+3];
  }
}
const compressed = zlib.deflateSync(raw, { level: 6 });

const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk('IHDR', ihdr),
  chunk('IDAT', compressed),
  chunk('IEND', Buffer.alloc(0)),
]);

const outDir = path.join(__dirname, '..', 'assets', 'icon');
fs.mkdirSync(outDir, { recursive: true });
const outPath = path.join(outDir, 'icon.png');
fs.writeFileSync(outPath, png);
console.log('✓ Icon generated:', outPath, `(${(png.length / 1024).toFixed(0)} KB)`);
