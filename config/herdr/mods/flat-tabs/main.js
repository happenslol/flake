// The tab bar, along the bottom: flat tabs that carry their number and what a
// pane header would (the program's icon, its name or the tab's, its folder, the
// agent's state), for the focused pane in the shown tab, else the tab's agent or
// first pane. Then the + menu and the Files / Changes panel buttons.
// Keys: "flat-tabs.move_left" / "flat-tabs.move_right" move the shown tab one
// place, wrapping around at the ends; "flat-tabs.tab_<n>" shows the nth tab,
// and does nothing (no warning) when there isn't one.

import { View, div, svg, image } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, run, openOverlay, theme, shared, layout, home, nextCommand } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

function folder(cwd) {
  if (!cwd) return "";
  const h = home();
  return cwd === h ? "~" : cwd.startsWith(h + "/") ? "~" + cwd.slice(h.length) : cwd;
}

// The pane a tab speaks for.
function lead(tab, all) {
  const mine = all.filter((p) => p.tab === tab.id);
  return mine.find((p) => p.focused) ?? mine.find((p) => p.program?.agent) ?? mine.find((p) => p.terminal) ?? mine[0];
}

export default class Tabs extends View {
  init(_props, cx) {
    this.pressed = null;
    this.panels = JSON.parse(localStorage.getItem("panels") ?? "{}");
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        this.command(c);
        cx.notify();
      }
    });
  }

  command(c) {
    const space = spaces().find(p => p.active);
    if (!space) return;
    // Counted as tab.select counts them: settled tabs skipped.
    const pick = /^tab_(\d+)$/.exec(c);
    if (pick) {
      const tab = space.tabs.filter(x => !x.settled)[Number(pick[1]) - 1];
      if (tab) run("tab.select", { id: tab.id });
      return;
    }
    const step = { move_left: -1, move_right: 1 }[c];
    const tab = space.tabs.find(x => x.active);
    if (!step || !tab || space.tabs.length < 2) return;
    const n = space.tabs.length;
    run("tab.move", { id: tab.id, index: ((tab.index - 1 + step + n) % n) + 1 });
  }

  // The side panel is remembered per space: switching shows that space's choice
  // (closed if it never had one), and opening or closing it records it.
  syncPanel(space, panel, body, enabled) {
    if (!space || !panel) return;
    const now = panel.hidden ? null : body?.active ?? null;
    if (space.id !== this.space) {
      const first = this.space === undefined;
      this.space = space.id; this.pending = null;
      if (!(first && !(space.id in this.panels))) {
        const stored = this.panels[space.id] ?? null, want = enabled.includes(stored) ? stored : null;
        if (want !== now) {
          this.pending = { want, until: Date.now() + 1000 };
          if (want) { run("layout.select", { stack: "panel-body", child: want }); run("layout.show", { id: "panel" }); }
          else run("layout.hide", { id: "panel" });
          return;
        }
      }
    }
    // Until the restore lands (or something else won), the old state isn't a choice.
    if (this.pending) {
      if (this.pending.want !== now && Date.now() < this.pending.until) return;
      this.pending = null;
    }
    if (this.panels[space.id] === now) return;
    this.panels[space.id] = now;
    localStorage.setItem("panels", JSON.stringify(this.panels));
  }

  render() {
    const t = theme();
    const space = spaces().find(p => p.active);
    const shown = space?.tabs ?? [];
    const all = panes();
    const stop = (_e, cx) => cx.stop_propagation();
    const button = (id, label, action) => div().id(id).size(26).flex_none().flex().items_center().justify_center().rounded(6).text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground))
      .on_mouse_down("left", stop).on_click(action).child(label);
    const item = (c, i) => {
      const p = lead(c, all);
      const program = p?.program;
      // As a pane header named it: the agent or shell, else the program's title.
      const name = c.named ? c.name : ((program?.agent || program?.shell) && program.name) || p?.title || program?.name || "shell";
      const where = folder(p?.cwd);
      return h_flex().id(`tab-${c.id}`).h_full().px(12).gap(7).items_center().flex_none().text_size(12.5)
        .bg(c.active ? t.selected : t.chrome).text_color(c.active ? t.foreground : t.muted)
        .when(!c.active, el => el.hover(s => s.bg(t.hover)))
        .on_mouse_down("left", (e, cx) => { cx.stop_propagation(); this.pressed = i; if (e.click_count === 2) run("tab.rename", { id: c.id }); })
        .on_mouse_up("left", () => {
          const from = this.pressed; this.pressed = null;
          if (from !== null && from !== i) run("tab.move", { id: shown[from].id, index: space.tabs.findIndex(x => x.id === c.id) + 1 });
          else run("tab.select", { id: c.id });
        })
        .on_mouse_down("right", () => openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: { id: c.id, space: space.id } } }))
        .child(div().flex_none().text_color(c.active ? t.muted : t.dim).child(String(c.index)))
        .when(Boolean(program?.icon), el => el.child(program.tint ? svg(program.icon).size(14).flex_none().text_color(t.muted) : image(program.icon).size(14).flex_none()))
        .child(div().max_w(220).truncate().child(name))
        .when(Boolean(where), el => el.child(div().max_w(220).truncate().text_color(t.dim).child(where)))
        .when(c.zoomed, el => el.child(svg("mods/flat-tabs/zoom.svg").size(12).flex_none().text_color(t.dim)))
        .when(c.status === "working", el => el.child(svg("mods/flat-tabs/spinner.svg").size(12).flex_none().text_color(t.working).spin(900)))
        .when(c.status === "blocked" || c.status === "done", el => el.child(div().size(6).rounded(3).flex_none().bg(t[c.status])));
    };
    const root = layout();
    const panel = find(root, "panel"), body = find(root, "panel-body");
    const enabled = shared("workspace.panels") ?? ["files", "changes"];
    this.syncPanel(space, panel, body, enabled);
    const panelButton = (id, label, icon) => {
      const on = panel && !panel.hidden && body?.active === id;
      return h_flex().id(`panel-${id}`).h(24).px(8).gap(5).flex_none().items_center().rounded(6)
        .text_size(12).bg(on ? t.selected : t.chrome).text_color(on ? t.foreground : t.muted)
        .hover(s => s.bg(t.hover)).on_mouse_down("left", stop)
        .on_click(() => {
          if (on) run("layout.hide", { id: "panel" });
          else { run("layout.select", { stack: "panel-body", child: id }); run("layout.show", { id: "panel" }); }
        }).child(svg(icon).size(14)).child(label);
    };
    return h_flex().size_full().min_w(0).pr(8).gap(3).items_center().bg(t.chrome).border_t(1).border_color(t.border)
      .on_mouse_up("left", () => { this.pressed = null; })
      .on_scroll_wheel(e => { if (Math.abs(e.delta.y) >= 1) run(e.delta.y > 0 ? "tab.prev" : "tab.next"); })
      .child(h_flex().id("tab-scroll").flex_1().min_w(0).h_full().items_center().overflow_x_scrollbar().children(shown.map(item)))
      .child(button("tab-new", "+", () => openOverlay({ mod: "new-menu", kind: "popup", width: 250, height: 512 })))
      .when(enabled.includes("files"), el => el.child(panelButton("files", "Files", "mods/flat-tabs/files.svg")))
      .when(enabled.includes("changes"), el => el.child(panelButton("changes", "Changes", "mods/flat-tabs/changes.svg")));
  }
}
