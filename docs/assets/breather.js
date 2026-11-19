// The break screen for the web: the mesh gradient from BreathingBackground.swift,
// the dotted ring from BreakView.swift and the menu bar ring from MenuBarIcon.swift.
window.Breather = (() => {
  const THEMES = {
    sunset: {
      name: 'Sunset',
      grid: [0x1B1230, 0x3A1D45, 0x140E22, 0x5C2448, 0x8E3B4F, 0x3A1D45, 0xB0613E, 0x6E2C45, 0x1B1230],
      glow: 0xB65A4E,
    },
    lavender: {
      name: 'Lavender dusk',
      grid: [0x2A2350, 0x4A3B7A, 0x1E1A3E, 0x5A4A8E, 0x6E5A9E, 0x3A3A72, 0xA2687A, 0x7A4E86, 0x2A2350],
      glow: 0x8A74B8,
    },
    deepBlue: {
      name: 'Deep blue',
      grid: [0x050B22, 0x1A1F5E, 0x07102E, 0x0E2A6B, 0x1E4E9E, 0x221C63, 0x0A3A5C, 0x162C78, 0x040918],
      glow: 0x2F7AC4,
    },
    forest: {
      name: 'Forest',
      grid: [0x0A1A14, 0x1C3A2C, 0x0D2226, 0x234A33, 0x3B6B4A, 0x14363A, 0x6B6232, 0x2A4A30, 0x08140F],
      glow: 0x5A8A60,
    },
  };
  // Neighbors are close in hue, so the fades stay clean.
  const ROTATION = ['sunset', 'lavender', 'deepBlue', 'forest'];

  function toLab(hex) {
    const linear = (byte) => {
      const c = (byte & 0xFF) / 255;
      return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    };
    const r = linear(hex >> 16), g = linear(hex >> 8), b = linear(hex);
    const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return [
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    ];
  }

  function toRGB([L, a, b]) {
    const l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3);
    const m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3);
    const s = Math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3);
    const gamma = (c) => {
      c = Math.min(1, Math.max(0, c));
      return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
    };
    return [
      gamma(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
      gamma(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
      gamma(-0.0041960771 * l - 0.7034186147 * m + 1.7076147010 * s),
    ];
  }

  const mix = (x, y, f) => x.map((v, i) => v + (y[i] - v) * f);
  const smooth = (x) => x * x * (3 - 2 * x);
  const LAB = Object.fromEntries(
    Object.entries(THEMES).map(([key, theme]) => [key, { grid: theme.grid.map(toLab), glow: toLab(theme.glow) }])
  );

  const VERTEX = `
    attribute vec2 uv;
    uniform vec2 P[9];
    uniform vec3 C[9];
    varying vec3 color;

    // The patch runs through all nine points.
    vec3 through(float t) {
      return vec3(2.0 * (t - 0.5) * (t - 1.0), -4.0 * t * (t - 1.0), 2.0 * t * (t - 0.5));
    }

    // A cubic through the three colors, so no creases show at the middle row and column.
    vec3 blend(float t) {
      float s = t < 0.5 ? 2.0 * t : 2.0 * t - 1.0;
      float h00 = 2.0 * s * s * s - 3.0 * s * s + 1.0;
      float h10 = s * s * s - 2.0 * s * s + s;
      float h01 = -2.0 * s * s * s + 3.0 * s * s;
      float h11 = s * s * s - s * s;
      return t < 0.5
        ? vec3(h00 - h10 - 0.5 * h11, h01 + h10, 0.5 * h11)
        : vec3(-0.5 * h10, h00 - h11, h01 + 0.5 * h10 + h11);
    }

    void main() {
      vec3 px = through(uv.x), py = through(uv.y);
      vec3 cx = blend(uv.x), cy = blend(uv.y);
      vec2 point = vec2(0.0);
      vec3 sum = vec3(0.0);
      for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 3; i++) {
          point += px[i] * py[j] * P[j * 3 + i];
          sum += cx[i] * cy[j] * C[j * 3 + i];
        }
      }
      color = clamp(sum, 0.0, 1.0);
      gl_Position = vec4(point.x * 2.0 - 1.0, 1.0 - point.y * 2.0, 0.0, 1.0);
    }`;

  // Fine noise keeps the large, dark gradient from banding.
  const FRAGMENT = `
    #ifdef GL_FRAGMENT_PRECISION_HIGH
    precision highp float;
    #else
    precision mediump float;
    #endif
    varying vec3 color;
    uniform float scale;

    void main() {
      vec2 cell = floor(gl_FragCoord.xy / scale);
      float noise = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
      vec3 overlay = mix(2.0 * color * noise, 1.0 - 2.0 * (1.0 - color) * (1.0 - noise), step(0.5, color));
      gl_FragColor = vec4(mix(color, overlay, 0.05), 1.0);
    }`;

  /// Draws the gradient into `canvas`. Each theme stays for `hold` seconds, then fades into the next for `fade`.
  function gradient(canvas, { theme = 'sunset', hold = 20, fade = 12 } = {}) {
    const gl = canvas.getContext('webgl', { antialias: false, alpha: false });
    if (!gl) return null;

    const program = gl.createProgram();
    for (const [type, source] of [[gl.VERTEX_SHADER, VERTEX], [gl.FRAGMENT_SHADER, FRAGMENT]]) {
      const shader = gl.createShader(type);
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.warn(gl.getShaderInfoLog(shader));
        return null;
      }
      gl.attachShader(program, shader);
    }
    gl.linkProgram(program);
    gl.useProgram(program);

    const cells = 48;
    const vertices = [], indices = [];
    for (let y = 0; y <= cells; y++) {
      for (let x = 0; x <= cells; x++) vertices.push(x / cells, y / cells);
    }
    for (let y = 0; y < cells; y++) {
      for (let x = 0; x < cells; x++) {
        const i = y * (cells + 1) + x;
        indices.push(i, i + 1, i + cells + 1, i + 1, i + cells + 2, i + cells + 1);
      }
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, gl.createBuffer());
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);
    const uv = gl.getAttribLocation(program, 'uv');
    gl.enableVertexAttribArray(uv);
    gl.vertexAttribPointer(uv, 2, gl.FLOAT, false, 0, 0);
    const uPoints = gl.getUniformLocation(program, 'P');
    const uColors = gl.getUniformLocation(program, 'C');
    const uScale = gl.getUniformLocation(program, 'scale');

    const clock = () => Date.now() / 1000;
    let first = Math.max(0, ROTATION.indexOf(theme));
    let since = clock();
    // The colors on screen when the visitor picked a theme. They fade into the picked one.
    let picked = null;
    // How far a rush has moved the mesh and the themes ahead of the clock, in seconds.
    let ahead = { waves: 0, themes: 0 };
    let rushing = null;

    function shift(now) {
      if (!rushing) return ahead;
      const x = (now - rushing.at) / rushing.seconds;
      if (x >= 1) {
        ahead = { waves: ahead.waves + rushing.waves, themes: ahead.themes + rushing.themes };
        rushing = null;
        return ahead;
      }
      const eased = x * x * x * (x * (6 * x - 15) + 10);
      return { waves: ahead.waves + rushing.waves * eased, themes: ahead.themes + rushing.themes * eased };
    }

    function colors(t) {
      const elapsed = Math.max(0, t - since);
      const step = Math.floor(elapsed / (hold + fade));
      const progress = smooth(Math.min(1, Math.max(0, (elapsed % (hold + fade)) - hold) / fade));
      const from = LAB[ROTATION[(first + step) % ROTATION.length]];
      const to = LAB[ROTATION[(first + step + 1) % ROTATION.length]];
      let grid = from.grid.map((color, i) => mix(color, to.grid[i], progress));
      let glow = mix(from.glow, to.glow, progress);
      if (picked) {
        const x = (t - picked.at) / 1.5;
        if (x >= 1) {
          picked = null;
        } else {
          grid = picked.grid.map((color, i) => mix(color, grid[i], smooth(x)));
          glow = mix(picked.glow, glow, smooth(x));
        }
      }
      return { grid, glow };
    }

    function resize() {
      const scale = Math.min(window.devicePixelRatio || 1, 2);
      const width = Math.round(canvas.clientWidth * scale), height = Math.round(canvas.clientHeight * scale);
      if (canvas.width !== width || canvas.height !== height) {
        canvas.width = width;
        canvas.height = height;
      }
      gl.viewport(0, 0, width, height);
      gl.uniform1f(uScale, scale);
    }

    function draw() {
      const now = clock();
      const { waves, themes } = shift(now);
      const { grid, glow } = colors(now + themes);
      const t = now + waves;
      const wave = (period, phase) => Math.sin((t * 2 * Math.PI) / period + phase);
      // The middle brightens and dims on a ten-second cycle, about one calm breath.
      const breath = (wave(10, 0) + 1) / 2;
      resize();
      gl.uniform2fv(uPoints, [
        0, 0, 0.5 + 0.2 * wave(19, 0), 0, 1, 0,
        0, 0.5 + 0.2 * wave(17, 1), 0.5 + 0.18 * wave(13, 2), 0.45 + 0.12 * wave(11, 3), 1, 0.5 + 0.2 * wave(21, 4),
        0, 1, 0.5 + 0.2 * wave(23, 5), 1, 1, 1,
      ]);
      gl.uniform3fv(uColors, grid.flatMap((color, i) => toRGB(i === 4 ? mix(color, glow, 0.8 * breath) : color)));
      gl.drawElements(gl.TRIANGLES, indices.length, gl.UNSIGNED_SHORT, 0);
    }

    const still = window.matchMedia('(prefers-reduced-motion: reduce)');
    let last = 0;
    function frame(now) {
      if (now - last >= 1000 / 30 - 2) {
        last = now;
        draw();
      }
      if (!still.matches) requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
    window.addEventListener('resize', draw);
    still.addEventListener('change', () => requestAnimationFrame(frame));

    return {
      setTheme(key) {
        if (!(key in LAB)) return;
        const t = clock() + shift(clock()).themes;
        picked = { ...colors(t), at: t };
        first = ROTATION.indexOf(key);
        since = t;
        if (still.matches) draw();
      },
      /// Plays the mesh fast for a moment and races the colors through the next theme, landing on the one after it.
      /// The amounts grow with the time, so a short rush doesn't flicker.
      rush(seconds = 1.6) {
        if (still.matches || rushing) return;
        rushing = { at: clock(), seconds, waves: 11 * seconds, themes: 2 * (hold + fade) };
      },
    };
  }

  /// A random theme to start with, never the one the last visit started with.
  function nextTheme() {
    let last = null;
    try { last = localStorage.getItem('breather-theme'); } catch {}
    const choices = ROTATION.filter((key) => key !== last);
    const pick = choices[Math.floor(Math.random() * choices.length)];
    try { localStorage.setItem('breather-theme', pick); } catch {}
    return pick;
  }

  const SVG = 'http://www.w3.org/2000/svg';
  function element(name, attributes, parent) {
    const node = document.createElementNS(SVG, name);
    for (const [key, value] of Object.entries(attributes)) node.setAttribute(key, value);
    parent?.appendChild(node);
    return node;
  }

  let rings = 0;

  /// Dots run clockwise from the top. Lit dots are the time still ahead.
  function ring(svg, { count = 120 } = {}) {
    const id = `ring-glow-${rings++}`;
    svg.setAttribute('viewBox', '0 0 300 300');
    svg.setAttribute('aria-hidden', 'true');
    const defs = element('defs', {}, svg);
    const filter = element('filter', { id, x: '-10%', y: '-10%', width: '120%', height: '120%' }, defs);
    element('feGaussianBlur', { stdDeviation: 5 }, filter);
    const glowGroup = element('g', { filter: `url(#${id})`, fill: 'currentColor' }, svg);
    const dotGroup = element('g', { fill: 'currentColor' }, svg);
    const dots = [], glows = [], flights = [];
    for (let index = 0; index < count; index++) {
      const angle = (index / count) * 2 * Math.PI - Math.PI / 2;
      const at = { cx: 150 + 140 * Math.cos(angle), cy: 150 + 140 * Math.sin(angle) };
      glows.push(element('circle', { ...at, r: 2.72, opacity: 0 }, glowGroup));
      dots.push(element('circle', { ...at, r: 1.7, opacity: 0.16 }, dotGroup));
      // Where the dot flies when the ring scatters: how far out, how far around and how much it grows.
      flights.push({ angle, out: 50 + 520 * Math.random() ** 2, around: 0.5 + 1.3 * Math.random(), grow: 2.4 * Math.random() });
    }
    let shown = -1;
    return {
      /// Throws the dots off the ring. 0 is the ring, 1 is fully scattered, `turn` spins all of them around the center.
      scatter(amount, turn = 0, opacity = 1) {
        dotGroup.setAttribute('opacity', opacity);
        glowGroup.setAttribute('opacity', Math.max(0, 1 - 4 * amount));
        dots.forEach((dot, index) => {
          const flight = flights[index];
          const angle = flight.angle + flight.around * amount + turn;
          const radius = 140 + flight.out * amount;
          dot.setAttribute('cx', 150 + radius * Math.cos(angle));
          dot.setAttribute('cy', 150 + radius * Math.sin(angle));
          dot.setAttribute('r', 1.7 * (1 + flight.grow * Math.min(1, amount)));
        });
      },
      set(fraction) {
        const lit = Math.min(1, Math.max(0, fraction)) * count;
        if (Math.abs(lit - shown) < 0.01) return;
        shown = lit;
        for (let index = 0; index < count; index++) {
          // The dot at the edge fades out smoothly.
          const level = Math.min(1, Math.max(0, lit - index));
          dots[index].setAttribute('opacity', 0.16 + 0.84 * level);
          glows[index].setAttribute('opacity', 0.35 * level);
        }
      },
    };
  }

  /// The menu bar icon. The bright arc is the work left, the faint arc the work done.
  function icon(svg) {
    svg.setAttribute('viewBox', '0 0 18 18');
    svg.setAttribute('aria-hidden', 'true');
    const shared = { fill: 'none', stroke: 'currentColor', 'stroke-linecap': 'round' };
    const whole = element('circle', { ...shared, cx: 9, cy: 9, r: 6.4 }, svg);
    const done = element('path', { ...shared, 'stroke-width': 1.4, opacity: 0.4 }, svg);
    const left = element('path', { ...shared, 'stroke-width': 2 }, svg);
    const arc = (from, to) => {
      if (to - from <= 1) return '';
      const point = (degrees) => {
        const angle = ((degrees - 90) * Math.PI) / 180;
        return `${(9 + 6.4 * Math.cos(angle)).toFixed(3)} ${(9 + 6.4 * Math.sin(angle)).toFixed(3)}`;
      };
      return `M${point(from)}A6.4 6.4 0 ${to - from > 180 ? 1 : 0} 1 ${point(to)}`;
    };
    return {
      set(fraction) {
        fraction = Math.min(1, Math.max(0, fraction));
        const full = fraction === 1, empty = fraction === 0;
        whole.setAttribute('visibility', full || empty ? 'visible' : 'hidden');
        whole.setAttribute('stroke-width', full ? 2 : 1.4);
        whole.setAttribute('opacity', full ? 1 : 0.4);
        const split = 360 * fraction, gap = 30;
        left.setAttribute('d', full || empty ? '' : arc(0, split));
        done.setAttribute('d', full || empty ? '' : arc(split + gap, 360 - gap));
      },
    };
  }

  /// "4:12", rounded up so it reads "0:01" until the very end.
  function countdown(remaining) {
    const seconds = Math.max(0, Math.ceil(remaining));
    return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
  }

  /// "Break in 32 min".
  function breakIn(remaining) {
    if (remaining < 60) return 'Break in less than a minute';
    return `Break in ${Math.ceil(remaining / 60)} min`;
  }

  const SUGGESTIONS = [
    'Stand up and stretch.',
    'Look at something far away.',
    'Get a glass of water.',
    'Walk around for a bit.',
    'Roll your shoulders and breathe out slowly.',
    'Open a window.',
    'Close your eyes for a minute.',
  ];

  return { THEMES, ROTATION, SUGGESTIONS, gradient, nextTheme, ring, icon, countdown, breakIn };
})();
