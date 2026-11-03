---
name: steam-tags
description: >-
  Choose, order and publish the Steam store tags for a game: read the game's own design docs, collect the tags of
  comparable games from their store pages, decide the 20 tags and their order against Steam's tag rules, then apply them
  in the Steamworks Tag Wizard with the browser and confirm they were saved. Use for "fix the Steam tags", "are our tags
  right", "which tags should we use", "reorder the tags", or before a Next Fest / launch.
  「タグを見直して」「Steam のタグ大丈夫？」「タグ設定して」「タグの順番を直して」などで使う。
---

# Steam tags

Tags decide which shelves, "More Like This" rows and recommendations a game appears in. Decide them from evidence
(the game itself and what comparable games use), not from what sounds right.

## Steam's rules (partner docs, `store/tags`)

- Only the **top 20** tags count. Fill all 20.
- The **top 5** describe the game and weigh the most. Put the most specific, high-information tags there
  (sub-genre, the hook), and generic ones (Indie, Singleplayer, Casual, Adventure) at the bottom.
- For recommendations, **overlap with similar games** matters more than order, and **rare tags weigh more** than common
  ones. A rare tag that does not fit (e.g. Perma Death on a non-roguelike) pulls the game toward the wrong audience.
- Remove tags that are inaccurate. Community tags also mix in after release; recheck 1–2 weeks after launch.
- A demo inherits its base game's tags. Publishing tags is separate from the store page publish and its review, and
  takes effect without review.

## Procedure

1. **Read the game.** Its README, design doc and store copy (e.g. `docs/DESIGN.md`, `docs/steam/store_*.md`). Note the
   real mechanics: how failure works, length of a run, viewpoint, what is hidden from the player (do not spoil a hidden
   theme with a tag), and the AI-content disclosure.
2. **Read the current tags.** Public page: run the script below with the game's appid. Not public yet: open the Tag
   Wizard (step 6) and read the summary on the right.
3. **Collect comparables.** Find 6–10 similar games (`https://store.steampowered.com/api/storesearch/?term=...&cc=US&l=english`)
   and print their tags with the script. Count which tags most of them share.
4. **Decide 20 tags and their order**, and write the reason for every addition and removal. Show the user the list
   before touching Steamworks.
5. **Check tag names.** The wizard is in the account's language. English ↔ Japanese names (and tag ids):
   `https://store.steampowered.com/tagdata/populartags/english` and `.../japanese`. A tag missing from that list does
   not exist (e.g. "Spot the Difference").
6. **Apply in the Tag Wizard** (`https://partner.steamgames.com/taxonomy/tagwizard/<appid>`, Claude in Chrome):
   - Steps: top-level genre (max 2) → genre → sub-genre → visuals → themes → features → players → other → user tags →
     order → publish.
   - Toggling a choice: click the `input` inside the visible `div.choices div.choice` whose text is the tag name (JS
     `.click()` is reliable; coordinate clicks miss when the page scrolls).
   - "Other" (step 8, search box to add any tag) is skipped by "Next"/"Back". Open it by clicking **その他 / Other** in
     the right-hand summary. Going back and forth can untick tags in that step: re-read the summary before publishing.
   - Ordering: `#sortable` is a jQuery UI list. Re-append its `li` elements in the wanted order, then
     `jQuery('#sortable').sortable('refresh')`; the summary on the right follows.
   - Press 公開 / Publish, read the confirmation dialog (it lists the final 20 and the community tags it will remove),
     and confirm only with the user's go-ahead.
7. **Verify.** Reload the Tag Wizard and read the summary. The public store page catches up later (cache).

```bash
# Print a game's public tags in order (works for any appid; add &l=japanese for Japanese names)
python3 - 2653790 2903560 <<'EOF'
import re, json, sys, urllib.request
for a in sys.argv[1:]:
    req = urllib.request.Request(f"https://store.steampowered.com/app/{a}/?l=english",
        headers={"Cookie": "birthtime=0; lastagecheckage=1-0-1990; wants_mature_content=1"})
    s = urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "ignore")
    m = re.search(r"InitAppTagModal\(\s*\d+,\s*(\[.*?\])", s, re.S)
    print(a, ", ".join(t["name"] for t in json.loads(m.group(1))) if m else "(no tags / not public)")
EOF
```

## Lessons from past titles

- Anomaly-spotting games (The Exit 8 likes) use **Hidden Object (探し物)** as their genre marker: 6 of the 10 main titles.
  Put it in the top 5.
- Short = **短時間** in Japanese. Fits games that finish in about 10–30 minutes; short games travel well on streams.
- **Artificial Intelligence** reads as "made with AI" next to an AI-content disclosure, and players punish that. Keep it
  only when AI is an open, central theme.
- **Controller** adds almost nothing as a tag; Steam shows controller support separately.
- Retro-console horror sellers (KinitoPET, Buddy Simulator 1984, FAITH) share Psychological Horror, Retro, Pixel
  Graphics and 1990's.
