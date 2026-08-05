const LIMIT = 240;
const variantMeta = {
  A: { name: "聚焦画布", hint: "顶部入库 · 底部动作坞" },
  B: { name: "工具轨道", hint: "侧边动作 · 底部门把" },
  C: { name: "编辑台账", hint: "顶部命令 · 左上目录" },
};

const nearLimitSample = [
  "Before Friday / 周五之前：\n",
  "1. Confirm the launch copy with Mia；\n",
  "2. 把演示机、转接头和备用电源放进灰色帆布包；\n",
  "3. Send the revised deck before 16:30；\n",
  "4. 记得给妈妈回电话 ☎️。\n",
  "如果时间不够，先保证现场演示稳定，再补充截图和备注。Keep the message short, calm, and specific. 会后把反馈按“必须改 / 可以等 / 不做”整理，不要在回程路上凭印象做决定。🌿",
].join("");

const initialLibrary = () => [
  {
    id: crypto.randomUUID(),
    text: "明天 09:30 牙医复诊\n带上旧片子和医保卡 🦷",
    addedAt: Date.now() - 1_000,
  },
  {
    id: crypto.randomUUID(),
    text: "A quiet reminder:\nYou do not have to answer every message today. Take one thing at a time. 🌙",
    addedAt: Date.now() - 2_000,
  },
  {
    id: crypto.randomUUID(),
    text: "菜市场：番茄、鸡蛋、青柠、燕麦奶\nNo plastic bag, please. 🥚🍋",
    addedAt: Date.now() - 3_000,
  },
  {
    id: crypto.randomUUID(),
    text: clamp(nearLimitSample),
    addedAt: Date.now() - 4_000,
  },
];

const state = {
  currentNote: "",
  isPinned: false,
  library: initialLibrary(),
  characterCount: 0,
  recentAction: "原型已载入：当前便签为空白",
  page: "workbench",
  saveStatus: "等待输入",
  counterOpen: false,
  inspectorOpen: false,
  deleteConfirmOpen: false,
  toast: "",
  limitNotice: false,
};

const app = document.querySelector("#app");
let saveTimer;
let toastTimer;
let limitTimer;
const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");

function graphemes(text) {
  if (Intl.Segmenter) {
    return [...new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(text)].map(
      (part) => part.segment,
    );
  }
  return Array.from(text);
}

function count(text) {
  return graphemes(text).length;
}

function clamp(text) {
  return graphemes(text).slice(0, LIMIT).join("");
}

function hasContent(text = state.currentNote) {
  return text.trim().length > 0;
}

function formatTime(timestamp) {
  return new Intl.DateTimeFormat("zh-CN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).format(timestamp);
}

function escapeHTML(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function currentVariant() {
  const candidate = new URLSearchParams(location.search).get("variant")?.toUpperCase();
  return variantMeta[candidate] ? candidate : "A";
}

function appearance() {
  const reviewAppearance = new URLSearchParams(location.search).get("reviewAppearance");
  if (["light", "dark"].includes(reviewAppearance)) return reviewAppearance;
  return systemTheme.matches ? "dark" : "light";
}

function setVariant(next) {
  const url = new URL(location.href);
  url.searchParams.set("variant", next);
  history.replaceState({}, "", url);
  state.recentAction = `切换到方案 ${next} · ${variantMeta[next].name}`;
  render();
}

function cycleVariant(direction) {
  const variants = Object.keys(variantMeta);
  const index = variants.indexOf(currentVariant());
  setVariant(variants[(index + direction + variants.length) % variants.length]);
}

function showToast(message) {
  state.toast = message;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    state.toast = "";
    render();
  }, 1800);
}

function showLimitNotice() {
  state.limitNotice = true;
  clearTimeout(limitTimer);
  limitTimer = setTimeout(() => {
    state.limitNotice = false;
    render();
  }, 1800);
}

function updateNote(nextValue, forceOverLimit = false) {
  const clampedValue = clamp(nextValue);
  const wasOverLimit = forceOverLimit || clampedValue !== nextValue;
  state.currentNote = clampedValue;
  state.characterCount = count(state.currentNote);
  state.saveStatus = wasOverLimit ? "最多 240 个字符" : "正在自动保存…";
  state.recentAction = `编辑当前便签 · ${state.characterCount} 个字符`;
  if (wasOverLimit) showLimitNotice();
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    state.saveStatus = `已自动保存 ${formatTime(Date.now())}`;
    state.recentAction = `自动保存完成 · ${state.characterCount} 个字符`;
    render({ preserveEditorFocus: true });
  }, wasOverLimit ? 1800 : 520);
  render({ preserveEditorFocus: true });
}

function resetCurrent(action) {
  state.currentNote = "";
  state.characterCount = 0;
  state.isPinned = false;
  state.saveStatus = "等待输入";
  state.counterOpen = false;
  state.recentAction = action;
}

function togglePin() {
  if (!hasContent()) return;
  state.isPinned = !state.isPinned;
  state.recentAction = state.isPinned ? "已挂起当前便签" : "已取消挂起";
  showToast(state.isPinned ? "已挂起（仅模拟）" : "已取消挂起");
  render();
}

function archiveCurrent() {
  if (!hasContent()) return;
  const wasPinned = state.isPinned;
  state.library.unshift({
    id: crypto.randomUUID(),
    text: state.currentNote,
    addedAt: Date.now(),
  });
  resetCurrent(wasPinned ? "取消挂起，并将当前便签放入便签库" : "当前便签已放入便签库");
  showToast("已入库，当前槽位恢复为空白");
  render();
}

function requestDelete() {
  if (!hasContent()) return;
  state.deleteConfirmOpen = true;
  state.recentAction = "等待确认删除当前便签";
  render();
}

function confirmDelete() {
  const wasPinned = state.isPinned;
  state.deleteConfirmOpen = false;
  resetCurrent(wasPinned ? "取消挂起，并永久删除当前便签" : "当前便签已永久删除");
  showToast("便签已删除");
  render();
}

function swapFromLibrary(id) {
  const index = state.library.findIndex((note) => note.id === id);
  if (index < 0) return;
  const selected = state.library[index];
  const oldCurrent = state.currentNote;
  const oldWasPinned = state.isPinned;
  state.library.splice(index, 1);
  if (hasContent(oldCurrent)) {
    state.library.unshift({ id: crypto.randomUUID(), text: oldCurrent, addedAt: Date.now() });
  }
  state.currentNote = selected.text;
  state.characterCount = count(selected.text);
  state.isPinned = false;
  state.saveStatus = "已从便签库取回";
  state.page = "workbench";
  state.recentAction = oldWasPinned
    ? "先取消挂起，再与便签库中的旧便签交换"
    : hasContent(oldCurrent)
      ? "旧便签与当前便签已交换"
      : "旧便签已成为当前便签（空白未入库）";
  showToast(oldWasPinned ? "已取消挂起并完成交换" : "已设为当前便签");
  render();
}

function progressMarkup() {
  const ratio = Math.max(0, Math.min(1, state.characterCount / LIMIT));
  const dash = Math.round(ratio * 100);
  return `
    <button class="counter" data-action="counter" aria-label="已输入 ${state.characterCount} 个字符，上限 ${LIMIT} 个字符，还可输入 ${LIMIT - state.characterCount} 个字符" style="--progress:${dash}%">
      <span class="counter-ring" aria-hidden="true"></span>
      <span class="counter-dot"></span>
    </button>
    ${state.counterOpen ? `<div class="counter-popover" role="status"><span>已输入 <b>${state.characterCount}</b></span><span>还可输入 <b>${LIMIT - state.characterCount}</b></span></div>` : ""}
  `;
}

function editorMarkup(variant) {
  return `
    <div class="editor-shell editor-${variant.toLowerCase()} ${state.isPinned ? "is-pinned" : ""}">
      <textarea id="current-note" maxlength="1000" spellcheck="true" aria-label="当前便签编辑器" aria-describedby="limit-note" placeholder="输入想随时看到的内容，再挂到灵动岛">${escapeHTML(state.currentNote)}</textarea>
      <div class="editor-meta">
        <span class="save-state" aria-live="polite"><i></i>${state.saveStatus}</span>
        <span id="limit-note" class="sr-only">最多 240 个用户感知字符</span>
        <div class="counter-wrap">${progressMarkup()}</div>
      </div>
    </div>
  `;
}

function actionButton(action, label, options = {}) {
  const disabled = options.disabled ? "disabled" : "";
  const active = options.active ? "is-active" : "";
  const danger = options.danger ? "is-danger" : "";
  return `<button class="action-button ${active} ${danger}" data-action="${action}" ${disabled} aria-label="${label}"><span>${label}</span></button>`;
}

function actionSet() {
  const empty = !hasContent();
  return `
    ${actionButton("pin", state.isPinned ? "取消挂起" : "挂起", { disabled: empty, active: state.isPinned })}
    ${actionButton("archive", "放入便签库", { disabled: empty })}
    ${actionButton("delete", "删除", { disabled: empty, danger: true })}
  `;
}

function libraryButton(extraClass = "") {
  return `<button class="library-entry ${extraClass}" data-action="open-library" aria-label="便签库，共 ${state.library.length} 条"><span>便签库</span><b>${state.library.length}</b></button>`;
}

function islandStatusMarkup() {
  const label = state.isPinned
    ? `灵动岛紧凑态示意：已挂起，当前 ${state.characterCount} 个字符的内容已同步`
    : "灵动岛紧凑态示意：当前未挂起";
  return `<div class="compact-island ${state.isPinned ? "is-active" : ""}" role="img" aria-label="${label}"><span></span></div>`;
}

function variantA() {
  return `
    <section class="phone variant-a" aria-label="方案 A 聚焦画布">
      <header class="a-header">
        <div><span class="eyebrow">NOW / 当前</span><h1>这一张，先放在眼前。</h1></div>
        <div class="header-tools">${islandStatusMarkup()}${libraryButton("compact")}</div>
      </header>
      <div class="a-focus-mark"><span>${state.isPinned ? "PINNED" : "CURRENT NOTE"}</span></div>
      ${editorMarkup("A")}
      <nav class="a-action-dock" aria-label="当前便签操作">${actionSet()}</nav>
    </section>
  `;
}

function variantB() {
  return `
    <section class="phone variant-b" aria-label="方案 B 工具轨道">
      <header class="b-header"><span class="b-logo">当前便签</span>${islandStatusMarkup()}</header>
      <div class="b-layout">
        <aside class="b-rail" aria-label="当前便签操作"><span class="rail-label">动作</span>${actionSet()}</aside>
        <div class="b-workspace">
          <div class="b-status"><span>${state.isPinned ? "正在挂起" : "当前便签"}</span><strong>${state.isPinned ? "LIVE" : "01"}</strong></div>
          ${editorMarkup("B")}
        </div>
      </div>
      ${libraryButton("b-drawer-handle")}
    </section>
  `;
}

function variantC() {
  return `
    <section class="phone variant-c" aria-label="方案 C 编辑台账">
      <header class="c-header">
        <button class="c-catalog" data-action="open-library"><span>便签目录</span><b>${String(state.library.length).padStart(2, "0")}</b></button>
        <div class="c-title"><span>CURRENT</span><strong>当前便签</strong></div>
        ${islandStatusMarkup()}
      </header>
      <nav class="c-command-row" aria-label="当前便签操作">${actionSet()}</nav>
      <div class="c-rule"><span>${state.isPinned ? "已挂起 · 编辑会自动同步" : "未挂起 · 自动保存"}</span><span>纯文字 / 240</span></div>
      ${editorMarkup("C")}
      <footer class="c-footer"><span>MEMO № 001</span><span>${new Intl.DateTimeFormat("zh-CN", { month: "2-digit", day: "2-digit" }).format(Date.now())}</span></footer>
    </section>
  `;
}

function libraryMarkup(variant) {
  const labels = {
    A: ["便签库", "最近放入的便签排在最前"],
    B: ["从下方抽出的旧便签", "点一下，立即换到工作台"],
    C: ["便签目录 / ARCHIVE", "只浏览与取回，不在这里改动"],
  }[variant];
  const items = state.library.length
    ? state.library
        .map(
          (note, index) => `
          <button class="library-card" data-swap-id="${note.id}">
            <span class="library-index">${String(index + 1).padStart(2, "0")}</span>
            <span class="library-text">${escapeHTML(note.text)}</span>
            <span class="library-card-meta"><span>${count(note.text)} 字符</span><span>${index === 0 ? "最近入库" : "旧便签"}</span></span>
            <span class="swap-cue">点击立即交换</span>
          </button>`,
        )
        .join("")
    : `<div class="empty-library"><p>便签库还是空的</p></div>`;
  return `
    <section class="phone library-page library-${variant.toLowerCase()}" aria-label="方案 ${variant} 的便签库">
      <header class="library-header">
        <button class="back-button" data-action="back"><span>返回当前便签</span></button>
        ${islandStatusMarkup()}
      </header>
      <div class="library-heading"><span>LIBRARY · ${state.library.length}</span><h1>${labels[0]}</h1><p>${labels[1]}</p></div>
      <div class="library-list">${items}</div>
      <p class="library-boundary">评审提示：便签库内没有编辑、挂起或删除操作。</p>
    </section>
  `;
}

function inspectorMarkup() {
  const snapshot = {
    currentNote: state.currentNote,
    isPinned: state.isPinned,
    library: state.library.map((note) => ({
      text: note.text,
      characterCount: count(note.text),
      addedAt: note.addedAt,
    })),
    characterCount: state.characterCount,
    graphemeCount: state.characterCount,
    recentAction: state.recentAction,
  };
  return `
    <aside class="inspector ${state.inspectorOpen ? "is-open" : ""}">
      <button data-action="inspector" aria-expanded="${state.inspectorOpen}"><span>STATE INSPECTOR</span><b>${state.inspectorOpen ? "−" : "+"}</b></button>
      ${state.inspectorOpen ? `<div class="inspector-body"><p>仅供原型评审 · 非产品 UI</p><div class="sample-tools" aria-label="评审样例"><button data-sample="mixed">中英换行 Emoji</button><button data-sample="whitespace">纯空白</button><button data-sample="239">239</button><button data-sample="240">240</button><button data-sample="241">粘贴 241</button></div><pre>${escapeHTML(JSON.stringify(snapshot, null, 2))}</pre></div>` : ""}
    </aside>
  `;
}

function switcherMarkup(variant) {
  return `
    <nav class="prototype-switcher" aria-label="原型方案切换器">
      <button data-action="prev-variant" aria-label="上一个方案">上一</button>
      <div><span>THROWAWAY PROTOTYPE</span><strong>${variant} — ${variantMeta[variant].name}</strong><small>${variantMeta[variant].hint}</small></div>
      <button data-action="next-variant" aria-label="下一个方案">下一</button>
    </nav>
  `;
}

function modalMarkup() {
  if (!state.deleteConfirmOpen) return "";
  return `
    <div class="modal-backdrop" role="presentation">
      <section class="confirm-dialog" role="alertdialog" aria-modal="true" aria-labelledby="delete-title">
        <span class="dialog-kicker">不可恢复</span>
        <h2 id="delete-title">删除当前便签？</h2>
        <p>删除后无法恢复${state.isPinned ? "，并会同时取消挂起" : ""}。</p>
        <div><button data-action="cancel-delete">保留便签</button><button class="confirm-danger" data-action="confirm-delete">确认删除</button></div>
      </section>
    </div>
  `;
}

function render(options = {}) {
  const active = document.activeElement;
  const editorWasFocused = options.preserveEditorFocus && active?.id === "current-note";
  const selectionStart = editorWasFocused ? active.selectionStart : null;
  const selectionEnd = editorWasFocused ? active.selectionEnd : null;
  const variant = currentVariant();
  document.documentElement.dataset.theme = appearance();
  document.body.dataset.variant = variant;
  app.innerHTML = `
    <div class="prototype-stage">
      ${state.page === "library" ? libraryMarkup(variant) : variant === "A" ? variantA() : variant === "B" ? variantB() : variantC()}
      ${inspectorMarkup()}
      ${switcherMarkup(variant)}
      ${state.limitNotice || state.toast ? `<div class="toast" role="status">${escapeHTML(state.limitNotice ? "最多 240 个字符" : state.toast)}</div>` : ""}
      ${modalMarkup()}
    </div>
  `;
  if (editorWasFocused) {
    const editor = document.querySelector("#current-note");
    editor.focus();
    editor.setSelectionRange(selectionStart, selectionEnd);
  }
}

app.addEventListener("input", (event) => {
  if (event.target.matches("#current-note")) updateNote(event.target.value);
});

app.addEventListener("beforeinput", (event) => {
  if (!event.target.matches("#current-note") || !event.inputType.startsWith("insert")) return;
  if (typeof event.data !== "string") return;
  const target = event.target;
  const start = target.selectionStart ?? target.value.length;
  const end = target.selectionEnd ?? start;
  const selectedCount = count(target.value.slice(start, end));
  const available = LIMIT - (count(target.value) - selectedCount);
  const insertion = graphemes(event.data);
  if (insertion.length <= available) return;
  event.preventDefault();
  target.setRangeText(insertion.slice(0, Math.max(0, available)).join(""), start, end, "end");
  showLimitNotice();
  updateNote(target.value);
});

app.addEventListener("click", (event) => {
  const swapTarget = event.target.closest("[data-swap-id]");
  if (swapTarget) {
    swapFromLibrary(swapTarget.dataset.swapId);
    return;
  }
  const button = event.target.closest("[data-action]");
  const sampleButton = event.target.closest("[data-sample]");
  if (sampleButton) {
    const samples = {
      mixed: "Call Mom / 给妈妈回电话\n保留手动换行、空格与组合 Emoji 👨‍👩‍👧‍👦 👍🏽",
      whitespace: " \n\t　",
      239: "汉".repeat(239),
      240: "汉".repeat(240),
      241: "汉".repeat(241),
    };
    const isOverLimitSample = sampleButton.dataset.sample === "241";
    if (isOverLimitSample) state.inspectorOpen = false;
    updateNote(samples[sampleButton.dataset.sample], isOverLimitSample);
    if (isOverLimitSample) {
      state.saveStatus = "最多 240 个字符";
      showLimitNotice();
      render();
    }
    return;
  }
  if (!button || button.disabled) return;
  const actions = {
    pin: togglePin,
    archive: archiveCurrent,
    delete: requestDelete,
    "confirm-delete": confirmDelete,
    "cancel-delete": () => {
      state.deleteConfirmOpen = false;
      state.recentAction = "取消删除，保留当前便签";
      render();
    },
    "open-library": () => {
      state.page = "library";
      state.recentAction = "进入便签库";
      render();
    },
    back: () => {
      state.page = "workbench";
      state.recentAction = "返回当前便签工作台";
      render();
    },
    counter: () => {
      state.counterOpen = !state.counterOpen;
      state.recentAction = state.counterOpen ? "展开字符计数详情" : "收起字符计数详情";
      render();
    },
    inspector: () => {
      state.inspectorOpen = !state.inspectorOpen;
      render();
    },
    "prev-variant": () => cycleVariant(-1),
    "next-variant": () => cycleVariant(1),
  };
  actions[button.dataset.action]?.();
});

window.addEventListener("keydown", (event) => {
  const tag = event.target.tagName;
  if (["INPUT", "TEXTAREA"].includes(tag) || event.target.isContentEditable) return;
  if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
    event.preventDefault();
    cycleVariant(event.key === "ArrowLeft" ? -1 : 1);
  }
  if (event.key === "Escape" && state.deleteConfirmOpen) {
    state.deleteConfirmOpen = false;
    state.recentAction = "取消删除，保留当前便签";
    render();
  }
});

window.addEventListener("popstate", render);
systemTheme.addEventListener?.("change", () => {
  if (!new URLSearchParams(location.search).has("reviewAppearance")) render();
});
render();
