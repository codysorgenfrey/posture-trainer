const STORAGE_KEY = "posture_web_store_v1";

const DEFAULT_SCHEDULE_WEEKS = [
  { weekNumber: 1, daysPerWeek: 4, minutesPerDay: 20 },
  { weekNumber: 2, daysPerWeek: 5, minutesPerDay: 30 },
  { weekNumber: 3, daysPerWeek: 5, minutesPerDay: 45 },
  { weekNumber: 4, daysPerWeek: 5, minutesPerDay: 60 },
  { weekNumber: 5, daysPerWeek: 4, minutesPerDay: 45 },
  { weekNumber: 6, daysPerWeek: 3, minutesPerDay: 60 },
  { weekNumber: 7, daysPerWeek: 3, minutesPerDay: 25 },
  { weekNumber: 8, daysPerWeek: 2, minutesPerDay: 20 },
];

const MICRO_CHECKS = [
  "Feet stable, not wrapped around chair legs",
  "Hips not tucked under; sit on your sit bones",
  "Ribcage stacked over pelvis, not flared forward",
  "Shoulders gently down and back, not yanked",
  "Head over shoulders, chin slightly tucked",
];

const state = loadState();
let timerInterval = null;
let timerStartTs = null;
let timerTargetSeconds = 0;
let reminderTickInterval = null;
const reminderSentMap = new Set();
let deferredInstallPrompt = null;

const el = {
  tabs: document.querySelectorAll(".tab"),
  panels: document.querySelectorAll(".panel"),
  installAppBtn: document.getElementById("installAppBtn"),
  startProgramBtn: document.getElementById("startProgramBtn"),
  todayDueCard: document.getElementById("todayDueCard"),
  currentWeekLabel: document.getElementById("currentWeekLabel"),
  currentWeekStats: document.getElementById("currentWeekStats"),
  currentStreak: document.getElementById("currentStreak"),
  longestStreak: document.getElementById("longestStreak"),
  totalSessions: document.getElementById("totalSessions"),
  totalMinutes: document.getElementById("totalMinutes"),
  weekProgressText: document.getElementById("weekProgressText"),
  weekProgressBar: document.getElementById("weekProgressBar"),
  openSessionBtn: document.getElementById("openSessionBtn"),
  openLogBtn: document.getElementById("openLogBtn"),
  openMicroBtn: document.getElementById("openMicroBtn"),
  scheduleList: document.getElementById("scheduleList"),
  addWeekBtn: document.getElementById("addWeekBtn"),
  resetScheduleBtn: document.getElementById("resetScheduleBtn"),
  microCheckList: document.getElementById("microCheckList"),
  historyList: document.getElementById("historyList"),
  dailyReminderToggle: document.getElementById("dailyReminderToggle"),
  reminderTimeInput: document.getElementById("reminderTimeInput"),
  microReminderToggle: document.getElementById("microReminderToggle"),
  currentWeekSelect: document.getElementById("currentWeekSelect"),
  resetProgramBtn: document.getElementById("resetProgramBtn"),
  sessionDialog: document.getElementById("sessionDialog"),
  sessionTitle: document.getElementById("sessionTitle"),
  sessionSetup: document.getElementById("sessionSetup"),
  sessionRun: document.getElementById("sessionRun"),
  sessionDone: document.getElementById("sessionDone"),
  sessionDurationInput: document.getElementById("sessionDurationInput"),
  sessionTimer: document.getElementById("sessionTimer"),
  sessionProgress: document.getElementById("sessionProgress"),
  sessionDoneText: document.getElementById("sessionDoneText"),
  sessionCancelBtn: document.getElementById("sessionCancelBtn"),
  sessionStartBtn: document.getElementById("sessionStartBtn"),
  sessionFinishBtn: document.getElementById("sessionFinishBtn"),
  logDialog: document.getElementById("logDialog"),
  logDateInput: document.getElementById("logDateInput"),
  logDurationInput: document.getElementById("logDurationInput"),
  logNotesInput: document.getElementById("logNotesInput"),
  saveLogBtn: document.getElementById("saveLogBtn"),
  microDialog: document.getElementById("microDialog"),
  microDialogList: document.getElementById("microDialogList"),
};

bootstrap();

function bootstrap() {
  registerServiceWorker();
  wireEvents();
  wireInstallPrompt();
  renderMicroCheckList();
  refreshCurrentWeekIfNeeded();
  renderAll();
  startReminderTicker();
  syncReminderSettingsToServiceWorker();
}

function wireEvents() {
  el.tabs.forEach((tabBtn) => {
    tabBtn.addEventListener("click", () => {
      const tab = tabBtn.dataset.tab;
      setTab(tab);
    });
  });

  el.startProgramBtn.addEventListener("click", startProgram);
  el.installAppBtn.addEventListener("click", promptInstall);
  el.openSessionBtn.addEventListener("click", openSessionDialog);
  el.openLogBtn.addEventListener("click", openLogDialog);
  el.openMicroBtn.addEventListener("click", openMicroDialog);

  el.addWeekBtn.addEventListener("click", addWeek);
  el.resetScheduleBtn.addEventListener("click", () => {
    if (!window.confirm("Reset schedule to defaults?")) return;
    state.scheduleWeeks = cloneSchedule(DEFAULT_SCHEDULE_WEEKS);
    if (state.currentWeek > state.scheduleWeeks.length) {
      state.currentWeek = state.scheduleWeeks.length;
    }
    saveAndRender();
  });

  el.dailyReminderToggle.addEventListener("change", async () => {
    const enabled = el.dailyReminderToggle.checked;
    state.remindersEnabled = enabled;
    if (enabled) {
      const granted = await requestNotificationsIfNeeded();
      if (granted) {
        await registerBackgroundReminderSync();
      }
    }
    saveAndRender();
  });

  el.reminderTimeInput.addEventListener("change", () => {
    const [h, m] = el.reminderTimeInput.value.split(":").map(Number);
    state.reminderHour = Number.isFinite(h) ? h : 9;
    state.reminderMinute = Number.isFinite(m) ? m : 0;
    saveAndRender();
  });

  el.microReminderToggle.addEventListener("change", async () => {
    const enabled = el.microReminderToggle.checked;
    state.microCheckRemindersEnabled = enabled;
    if (enabled) {
      const granted = await requestNotificationsIfNeeded();
      if (granted) {
        await registerBackgroundReminderSync();
      }
    }
    saveAndRender();
  });

  el.currentWeekSelect.addEventListener("change", () => {
    state.currentWeek = Number(el.currentWeekSelect.value) || 1;
    saveAndRender();
  });

  el.resetProgramBtn.addEventListener("click", () => {
    if (!window.confirm("Reset program and delete all sessions?")) return;
    state.programStartDate = null;
    state.currentWeek = 0;
    state.sessions = [];
    saveAndRender();
  });

  el.sessionStartBtn.addEventListener("click", startSessionTimer);
  el.sessionFinishBtn.addEventListener("click", completeSessionTimer);
  el.sessionCancelBtn.addEventListener("click", stopSessionTimer);

  el.saveLogBtn.addEventListener("click", () => {
    const duration = clamp(Number(el.logDurationInput.value) || 30, 1, 180);
    const date = new Date(el.logDateInput.value);
    const notes = el.logNotesInput.value.trim();
    logSession({ durationMinutes: duration, date, notes, weekNumber: Math.max(state.currentWeek, 1) });
    el.logDialog.close();
  });
}

function setTab(tabName) {
  el.tabs.forEach((tabBtn) => {
    const active = tabBtn.dataset.tab === tabName;
    tabBtn.classList.toggle("is-active", active);
    tabBtn.setAttribute("aria-selected", String(active));
  });

  el.panels.forEach((panel) => {
    panel.classList.toggle("is-active", panel.id === tabName);
  });
}

function startProgram() {
  if (state.programStartDate) return;
  state.programStartDate = new Date().toISOString();
  state.currentWeek = 1;
  saveAndRender();
}

function openSessionDialog() {
  resetSessionDialog();
  el.sessionDialog.showModal();
}

function resetSessionDialog() {
  stopSessionTimer();
  el.sessionTitle.textContent = "Start Session";
  el.sessionSetup.classList.remove("hidden");
  el.sessionRun.classList.add("hidden");
  el.sessionDone.classList.add("hidden");
  el.sessionStartBtn.classList.remove("hidden");
  el.sessionFinishBtn.classList.add("hidden");
  el.sessionDurationInput.value = String(getRecommendedMinutes());
}

function startSessionTimer() {
  const minutes = clamp(Number(el.sessionDurationInput.value) || 30, 1, 180);
  timerTargetSeconds = minutes * 60;
  timerStartTs = Date.now();

  el.sessionTitle.textContent = "In Progress";
  el.sessionSetup.classList.add("hidden");
  el.sessionRun.classList.remove("hidden");
  el.sessionDone.classList.add("hidden");
  el.sessionStartBtn.classList.add("hidden");
  el.sessionFinishBtn.classList.remove("hidden");

  renderSessionTimer();
  timerInterval = window.setInterval(() => {
    renderSessionTimer();
    const elapsed = getElapsedSeconds();
    if (elapsed >= timerTargetSeconds) {
      completeSessionTimer();
    }
  }, 1000);
}

function stopSessionTimer() {
  if (timerInterval) {
    window.clearInterval(timerInterval);
    timerInterval = null;
  }
  timerStartTs = null;
  timerTargetSeconds = 0;
}

function getElapsedSeconds() {
  if (!timerStartTs) return 0;
  return Math.max(0, Math.floor((Date.now() - timerStartTs) / 1000));
}

function renderSessionTimer() {
  const elapsed = getElapsedSeconds();
  const remaining = Math.max(timerTargetSeconds - elapsed, 0);
  el.sessionTimer.textContent = formatTimer(remaining);
  const progress = timerTargetSeconds > 0 ? (elapsed / timerTargetSeconds) * 100 : 0;
  el.sessionProgress.style.width = `${Math.min(100, progress)}%`;
}

function completeSessionTimer() {
  const elapsed = Math.max(1, getElapsedSeconds());
  const minutes = Math.max(1, Math.round(elapsed / 60));
  logSession({ durationMinutes: minutes, date: new Date(), notes: "Live session", weekNumber: Math.max(state.currentWeek, 1) });
  stopSessionTimer();

  el.sessionTitle.textContent = "Session Complete";
  el.sessionSetup.classList.add("hidden");
  el.sessionRun.classList.add("hidden");
  el.sessionDone.classList.remove("hidden");
  el.sessionStartBtn.classList.add("hidden");
  el.sessionFinishBtn.classList.add("hidden");
  el.sessionDoneText.textContent = `${minutes} minute${minutes === 1 ? "" : "s"} logged.`;
}

function openLogDialog() {
  el.logDateInput.value = toInputDate(new Date());
  el.logDurationInput.value = String(getRecommendedMinutes());
  el.logNotesInput.value = "";
  el.logDialog.showModal();
}

function openMicroDialog() {
  el.microDialogList.innerHTML = "";
  MICRO_CHECKS.forEach((item) => {
    const row = document.createElement("label");
    row.className = "switch-row";
    row.innerHTML = `<span>${item}</span><input type="checkbox" />`;
    el.microDialogList.appendChild(row);
  });
  el.microDialog.showModal();
}

function addWeek() {
  const weekNumber = state.scheduleWeeks.length + 1;
  state.scheduleWeeks.push({ weekNumber, daysPerWeek: 3, minutesPerDay: 30 });
  saveAndRender();
}

function updateWeek(index, key, rawValue) {
  const value = clamp(Number(rawValue) || 0, key === "daysPerWeek" ? 1 : 5, key === "daysPerWeek" ? 7 : 180);
  state.scheduleWeeks[index][key] = value;
  saveAndRender(false);
}

function deleteWeek(index) {
  if (state.scheduleWeeks.length <= 1) {
    window.alert("Schedule must have at least one week.");
    return;
  }
  state.scheduleWeeks.splice(index, 1);
  state.scheduleWeeks.forEach((week, idx) => {
    week.weekNumber = idx + 1;
  });
  if (state.currentWeek > state.scheduleWeeks.length) {
    state.currentWeek = state.scheduleWeeks.length;
  }
  saveAndRender();
}

function moveWeek(index, direction) {
  const target = index + direction;
  if (target < 0 || target >= state.scheduleWeeks.length) return;
  const temp = state.scheduleWeeks[index];
  state.scheduleWeeks[index] = state.scheduleWeeks[target];
  state.scheduleWeeks[target] = temp;
  state.scheduleWeeks.forEach((week, idx) => {
    week.weekNumber = idx + 1;
  });
  saveAndRender();
}

function logSession({ durationMinutes, date, notes, weekNumber }) {
  state.sessions.push({
    id: crypto.randomUUID(),
    date: date.toISOString(),
    durationMinutes,
    weekNumber,
    notes,
  });
  saveAndRender();
}

function updateSession(id, patch) {
  const idx = state.sessions.findIndex((session) => session.id === id);
  if (idx === -1) return;
  state.sessions[idx] = { ...state.sessions[idx], ...patch };
  saveAndRender();
}

function deleteSession(id) {
  state.sessions = state.sessions.filter((session) => session.id !== id);
  saveAndRender();
}

function renderAll() {
  refreshCurrentWeekIfNeeded();
  renderToday();
  renderSchedule();
  renderHistory();
  renderSettings();
}

function renderToday() {
  const week = currentScheduleWeek();
  const streak = streakInfo();
  const sessionsThisWeek = getSessionsThisWeek();
  const dueToday = isSessionDueToday();

  const started = Boolean(state.programStartDate);
  el.startProgramBtn.classList.toggle("hidden", started);

  if (!started) {
    el.currentWeekLabel.textContent = "Not started";
    el.currentWeekStats.textContent = "Click Start Program to begin Week 1.";
  } else if (week) {
    el.currentWeekLabel.textContent = `Week ${state.currentWeek} of ${state.scheduleWeeks.length}`;
    el.currentWeekStats.textContent = `${week.minutesPerDay} min/day, ${week.daysPerWeek} days/week`;
  } else {
    el.currentWeekLabel.textContent = "Program complete";
    el.currentWeekStats.textContent = "You reached the end of the schedule.";
  }

  el.currentStreak.textContent = String(streak.currentStreak);
  el.longestStreak.textContent = String(streak.longestStreak);
  el.totalSessions.textContent = String(streak.totalSessions);
  el.totalMinutes.textContent = String(streak.totalMinutes);

  const target = week ? week.daysPerWeek : 0;
  const progress = target > 0 ? Math.min(1, sessionsThisWeek / target) : 0;
  el.weekProgressText.textContent = `${sessionsThisWeek} / ${target} sessions`;
  el.weekProgressBar.style.width = `${progress * 100}%`;

  if (dueToday) {
    el.todayDueCard.classList.remove("hidden");
    el.todayDueCard.innerHTML = `<strong>Session due today.</strong><p class="muted">Keep your streak alive with a quick session.</p>`;
  } else {
    el.todayDueCard.classList.add("hidden");
  }
}

function renderSchedule() {
  el.scheduleList.innerHTML = "";
  state.scheduleWeeks.forEach((week, index) => {
    const row = document.createElement("article");
    row.className = "schedule-week stack";

    const isCurrent = Boolean(state.programStartDate) && state.currentWeek === week.weekNumber;
    row.innerHTML = `
      <div class="schedule-row">
        <strong>Week ${week.weekNumber}${isCurrent ? " (Current)" : ""}</strong>
        <div>
          <button class="btn" data-action="up">Up</button>
          <button class="btn" data-action="down">Down</button>
          <button class="btn btn-danger" data-action="delete">Delete</button>
        </div>
      </div>
      <div class="schedule-row">
        <label>Days/week <input data-field="daysPerWeek" type="number" min="1" max="7" value="${week.daysPerWeek}" /></label>
        <label>Min/day <input data-field="minutesPerDay" type="number" min="5" max="180" step="5" value="${week.minutesPerDay}" /></label>
      </div>
    `;

    row.querySelectorAll("input").forEach((input) => {
      input.addEventListener("change", (event) => {
        updateWeek(index, input.dataset.field, event.target.value);
      });
    });

    row.querySelector('[data-action="delete"]').addEventListener("click", () => deleteWeek(index));
    row.querySelector('[data-action="up"]').addEventListener("click", () => moveWeek(index, -1));
    row.querySelector('[data-action="down"]').addEventListener("click", () => moveWeek(index, 1));

    el.scheduleList.appendChild(row);
  });
}

function renderMicroCheckList() {
  el.microCheckList.innerHTML = "";
  MICRO_CHECKS.forEach((text) => {
    const li = document.createElement("li");
    li.textContent = text;
    el.microCheckList.appendChild(li);
  });
}

function renderHistory() {
  el.historyList.innerHTML = "";
  const sessions = [...state.sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  if (sessions.length === 0) {
    el.historyList.innerHTML = '<p class="muted">No sessions yet.</p>';
    return;
  }

  sessions.forEach((session) => {
    const row = document.createElement("article");
    row.className = "history-row card";

    const date = new Date(session.date);
    const dateLabel = date.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });

    row.innerHTML = `
      <div>
        <strong>${dateLabel}</strong>
        <p class="muted">${session.durationMinutes} min, Week ${session.weekNumber}</p>
        ${session.notes ? `<p>${escapeHtml(session.notes)}</p>` : ""}
      </div>
      <div class="stack">
        <button class="btn" data-action="edit">Edit</button>
        <button class="btn btn-danger" data-action="delete">Delete</button>
      </div>
    `;

    row.querySelector('[data-action="delete"]').addEventListener("click", () => {
      deleteSession(session.id);
    });

    row.querySelector('[data-action="edit"]').addEventListener("click", () => {
      const durationRaw = window.prompt("Duration (minutes)", String(session.durationMinutes));
      if (durationRaw === null) return;
      const weekRaw = window.prompt("Week number", String(session.weekNumber));
      if (weekRaw === null) return;
      const notesRaw = window.prompt("Notes", session.notes || "");
      if (notesRaw === null) return;

      updateSession(session.id, {
        durationMinutes: clamp(Number(durationRaw) || session.durationMinutes, 1, 180),
        weekNumber: clamp(Number(weekRaw) || session.weekNumber, 1, Math.max(1, state.scheduleWeeks.length)),
        notes: notesRaw.trim(),
      });
    });

    el.historyList.appendChild(row);
  });
}

function renderSettings() {
  const hh = String(state.reminderHour).padStart(2, "0");
  const mm = String(state.reminderMinute).padStart(2, "0");

  el.dailyReminderToggle.checked = state.remindersEnabled;
  el.reminderTimeInput.value = `${hh}:${mm}`;
  el.microReminderToggle.checked = state.microCheckRemindersEnabled;

  el.currentWeekSelect.innerHTML = "";
  state.scheduleWeeks.forEach((week) => {
    const option = document.createElement("option");
    option.value = String(week.weekNumber);
    option.textContent = `Week ${week.weekNumber}`;
    if (week.weekNumber === state.currentWeek) option.selected = true;
    el.currentWeekSelect.appendChild(option);
  });
  el.currentWeekSelect.disabled = !state.programStartDate;
}

function refreshCurrentWeekIfNeeded() {
  if (!state.programStartDate) return;
  const expected = expectedWeekFromStartDate();
  const maxWeek = state.scheduleWeeks.length;
  const target = clamp(expected, 1, maxWeek);
  if (target > state.currentWeek) {
    state.currentWeek = target;
    saveState();
  }
}

function currentScheduleWeek() {
  return state.scheduleWeeks.find((w) => w.weekNumber === state.currentWeek) || null;
}

function expectedWeekFromStartDate() {
  if (!state.programStartDate) return null;
  const start = startOfDay(new Date(state.programStartDate));
  const now = startOfDay(new Date());
  const days = Math.floor((now - start) / 86400000);
  return Math.max(1, Math.floor(days / 7) + 1);
}

function getSessionsThisWeek() {
  const now = new Date();
  const day = now.getDay();
  const mondayOffset = day === 0 ? -6 : 1 - day;
  const start = startOfDay(new Date(now.getFullYear(), now.getMonth(), now.getDate() + mondayOffset));
  return state.sessions.filter((s) => new Date(s.date) >= start).length;
}

function hasSessionToday() {
  const today = startOfDay(new Date());
  return state.sessions.some((s) => +startOfDay(new Date(s.date)) === +today);
}

function isSessionDueToday() {
  if (!state.programStartDate || hasSessionToday()) return false;
  const week = currentScheduleWeek();
  if (!week) return false;
  return getSessionsThisWeek() < week.daysPerWeek;
}

function streakInfo() {
  const sortedDays = [...new Set(state.sessions.map((session) => +startOfDay(new Date(session.date))))]
    .sort((a, b) => b - a)
    .map((ts) => new Date(ts));

  if (sortedDays.length === 0) {
    return { currentStreak: 0, longestStreak: 0, totalSessions: 0, totalMinutes: 0 };
  }

  let currentStreak = 0;
  const today = startOfDay(new Date());
  const first = sortedDays[0];
  if (daysBetween(first, today) <= maxAllowedGap(today)) {
    currentStreak = 1;
    let previous = first;
    for (const day of sortedDays.slice(1)) {
      const diff = daysBetween(day, previous);
      const allowedGap = maxAllowedGap(day);
      if (diff <= allowedGap) {
        currentStreak += 1;
        previous = day;
      } else {
        break;
      }
    }
  }

  const ascending = [...sortedDays].reverse();
  let longestStreak = 1;
  let tempStreak = 1;
  for (let i = 1; i < ascending.length; i += 1) {
    const diff = daysBetween(ascending[i - 1], ascending[i]);
    const allowedGap = maxAllowedGap(ascending[i - 1]);
    if (diff <= allowedGap) {
      tempStreak += 1;
    } else {
      longestStreak = Math.max(longestStreak, tempStreak);
      tempStreak = 1;
    }
  }
  longestStreak = Math.max(longestStreak, tempStreak);

  const totalMinutes = state.sessions.reduce((sum, session) => sum + session.durationMinutes, 0);

  return {
    currentStreak,
    longestStreak,
    totalSessions: state.sessions.length,
    totalMinutes,
  };
}

function maxAllowedGap(date) {
  if (!state.programStartDate) return 1;
  const start = startOfDay(new Date(state.programStartDate));
  const day = startOfDay(date);
  const days = Math.floor((day - start) / 86400000);
  const weekNum = Math.max(1, Math.floor(days / 7) + 1);
  const week = state.scheduleWeeks.find((w) => w.weekNumber === weekNum);
  if (!week) return 1;
  return 7 - week.daysPerWeek + 1;
}

function startReminderTicker() {
  if (reminderTickInterval) window.clearInterval(reminderTickInterval);
  reminderTickInterval = window.setInterval(() => {
    maybeSendReminderNotifications();
  }, 30000);
}

async function requestNotificationsIfNeeded() {
  if (!("Notification" in window)) {
    window.alert("This browser does not support notifications.");
    return false;
  }
  if (Notification.permission === "granted") return true;
  const permission = await Notification.requestPermission();
  return permission === "granted";
}

function maybeSendReminderNotifications() {
  if (!("Notification" in window) || Notification.permission !== "granted") return;
  const now = new Date();
  const stamp = `${now.getFullYear()}-${now.getMonth()}-${now.getDate()}-${now.getHours()}-${now.getMinutes()}`;

  if (state.remindersEnabled && now.getHours() === state.reminderHour && now.getMinutes() === state.reminderMinute) {
    const id = `daily-${stamp}`;
    if (!reminderSentMap.has(id)) {
      new Notification("Posture Trainer", { body: "Time for your posture training session." });
      reminderSentMap.add(id);
    }
  }

  if (state.microCheckRemindersEnabled && [10, 14, 17].includes(now.getHours()) && now.getMinutes() === 0) {
    const id = `micro-${stamp}`;
    if (!reminderSentMap.has(id)) {
      new Notification("Posture Check", { body: "Quick scan: feet, pelvis, ribcage, shoulders, chin." });
      reminderSentMap.add(id);
    }
  }

  if (reminderSentMap.size > 400) {
    reminderSentMap.clear();
  }
}

function wireInstallPrompt() {
  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredInstallPrompt = event;
    el.installAppBtn.classList.remove("hidden");
  });

  window.addEventListener("appinstalled", () => {
    deferredInstallPrompt = null;
    el.installAppBtn.classList.add("hidden");
  });
}

async function promptInstall() {
  if (!deferredInstallPrompt) return;
  deferredInstallPrompt.prompt();
  await deferredInstallPrompt.userChoice;
  deferredInstallPrompt = null;
  el.installAppBtn.classList.add("hidden");
}

function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return;
  navigator.serviceWorker.register("./service-worker.js").catch(() => {
    // Ignore registration failures and continue in non-PWA mode.
  });
}

async function registerBackgroundReminderSync() {
  if (!("serviceWorker" in navigator)) return;
  try {
    const registration = await navigator.serviceWorker.ready;
    if (registration.periodicSync && typeof registration.periodicSync.register === "function") {
      await registration.periodicSync.register("posture-reminders", {
        minInterval: 15 * 60 * 1000,
      });
      return;
    }
    if (registration.sync && typeof registration.sync.register === "function") {
      await registration.sync.register("posture-reminders-sync");
    }
  } catch {
    // Sync APIs are optional and browser-dependent.
  }
}

function syncReminderSettingsToServiceWorker() {
  if (!("serviceWorker" in navigator)) return;
  const payload = {
    remindersEnabled: state.remindersEnabled,
    microCheckRemindersEnabled: state.microCheckRemindersEnabled,
    reminderHour: state.reminderHour,
    reminderMinute: state.reminderMinute,
    lastSentStamp: "",
  };

  navigator.serviceWorker.ready
    .then((registration) => {
      if (registration.active) {
        registration.active.postMessage({
          type: "UPDATE_REMINDER_SETTINGS",
          payload,
        });
      }
    })
    .catch(() => {
      // Worker not ready yet; reminders still work while tab is open.
    });
}

function getRecommendedMinutes() {
  const week = currentScheduleWeek();
  return week ? week.minutesPerDay : 30;
}

function saveAndRender(save = true) {
  if (save) saveState();
  syncReminderSettingsToServiceWorker();
  renderAll();
}

function saveState() {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function loadState() {
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (!raw) return createDefaultState();

  try {
    const parsed = JSON.parse(raw);
    return {
      sessions: Array.isArray(parsed.sessions) ? parsed.sessions : [],
      programStartDate: parsed.programStartDate || null,
      currentWeek: Number(parsed.currentWeek) || 0,
      reminderHour: Number.isInteger(parsed.reminderHour) ? parsed.reminderHour : 9,
      reminderMinute: Number.isInteger(parsed.reminderMinute) ? parsed.reminderMinute : 0,
      remindersEnabled: Boolean(parsed.remindersEnabled),
      microCheckRemindersEnabled: Boolean(parsed.microCheckRemindersEnabled),
      scheduleWeeks: normalizeSchedule(parsed.scheduleWeeks),
    };
  } catch {
    return createDefaultState();
  }
}

function createDefaultState() {
  return {
    sessions: [],
    programStartDate: null,
    currentWeek: 0,
    reminderHour: 9,
    reminderMinute: 0,
    remindersEnabled: false,
    microCheckRemindersEnabled: false,
    scheduleWeeks: cloneSchedule(DEFAULT_SCHEDULE_WEEKS),
  };
}

function normalizeSchedule(scheduleWeeks) {
  if (!Array.isArray(scheduleWeeks) || scheduleWeeks.length === 0) {
    return cloneSchedule(DEFAULT_SCHEDULE_WEEKS);
  }
  return scheduleWeeks.map((week, index) => ({
    weekNumber: index + 1,
    daysPerWeek: clamp(Number(week.daysPerWeek) || 3, 1, 7),
    minutesPerDay: clamp(Number(week.minutesPerDay) || 30, 5, 180),
  }));
}

function cloneSchedule(weeks) {
  return weeks.map((week) => ({ ...week }));
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function daysBetween(a, b) {
  return Math.floor((startOfDay(b) - startOfDay(a)) / 86400000);
}

function toInputDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function formatTimer(totalSeconds) {
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
