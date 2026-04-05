# Basketball - Prototype 🏀

Permainan basketball Roblox dengan mekanik **accuracy-based shooting**, **stamina system**, dan **animasi code-based** (tanpa Animation ID). Half-court, free play, 1 ring.

---

## 🎮 Kontrol Permainan

| Tombol | Aksi |
|--------|------|
| **E** | Ambil bola / Lepas bola |
| **LMB (Klik Kiri)** | Tahan untuk charge shot, lepas untuk melempar |
| **F** | Pass ke pemain terdekat dalam arah kamera |
| **LeftShift** | Sprint (menguras stamina) |

---

## ✨ Fitur Utama

### 1. **Sistem Shooting Akurat**
- **Power Bar Vertikal** — marker bergerak naik-turun sinusoid
- **Green Sweet Spot (62%-78%)** — zona akurat release
- **Accuracy Scaling** — semakin tepat release → semakin akurat bola masuk
  - Inside green zone: accuracy **0.7 → 1.0**
  - Outside: accuracy falls off **0.7 → 0.0**
- **Arc Trajectory** — bola selalu melengkung ke ring, random offset untuk inaccuracy

### 2. **Animasi Throw Lengkap**
- **Windup** — bola di atas kepala, badan condong ke belakang (0.32s)
- **Snap Release** — lengan maju cepat saat lepas (0.10s snap)
- **Follow-Through** — arm tetap terentang sebentar (0.28s)
- **Return to Idle** — kembali ke posisi awal (0.75s total)
- **Jump Shoot** — karakter melompat otomatis saat shoot

### 3. **Stamina System**
- **Horizontal Bar** — pinggang bawah karakter, pill-shaped
- **Warna Dinamis** — hijau (100%) → kuning (50%) → merah (0%)
- **Drain mechanic:**
  - Sprint: 20 stamina/s
  - Dribble: +5 stamina/s tambahan saat pegang bola
- **Regen:** 15 stamina/s saat idle
- **Auto-stop:** Sprint otomatis berhenti saat stamina habis

### 4. **Dribble Animation**
- **Sine-wave bounce** — bola naik-turun saat dipegang
- Sinkron dengan arm animation (DribbleDown ↔ DribbleUp)
- Smooth visual menggunakan AlignPosition attachment offset

### 5. **UI & HUD**
- **Stamina Bar** — BillboardGui di kaki karakter (worldspace)
- **Shot Power Bar** — vertical bar di sisi kanan (screenspace), hanya muncul saat charging
  - Marker bergerak 0.8 oscillations/second
  - Green sweet spot band terlihat 62%-78%
  - Marker berubah warna: hijau (good) / putih (off)
- **Score Display** — top-center screenspace, update real-time

### 6. **Scoring System**
- **Two-zone detection** — bola harus masuk dari atas rim ke bawah
  - Top zone di Y=10 (rim height)
  - Bottom zone di Y=8.5 (1.5 studs di bawah rim)
- **Timeout 1.5s** — bola harus complete top→bottom dalam jangka waktu ini
- **Per-player score** — tracking score setiap pemain

---

## 🏗️ Arsitektur

### Struktur File

```
src/
  shared/
    Constants.luau            ← All tuning values
    RemoteNames.luau          ← Remote event names
    BallState.luau            ← Enum: Free, Held, Shot, Passed

  server/
    init.server.luau          ← Boot sequence
    RemoteSetup.luau          ← Create RemoteEvents
    HoopBuilder.luau          ← Build hoop model
    BallManager.luau          ← Ball state machine & physics
    ScoreDetector.luau        ← Two-zone scoring logic

  client/
    init.client.luau          ← Boot sequence & input wiring
    InputController.luau      ← Keybinding to callbacks
    ArmAnimator.luau          ← Motor6D C0 tweening
    BallAnimator.luau         ← Dribble oscillation
    StaminaController.luau    ← Stamina drain/regen
    ShotPowerController.luau  ← Marker oscillation & accuracy calc
    UI/
      init.luau               ← ScreenGui & widget mounting
      CircularRing.luau       ← Reusable arc-ring (two-half-circle clipping)
      StaminaRing.luau        ← Horizontal bar BillboardGui
      ShotPowerRing.luau      ← Vertical power bar
      ScoreDisplay.luau       ← Score TextLabel
```

### Server-Client Flow

1. **Server** — authoritative ball state, validates all actions (pickup/drop/shoot/pass)
2. **Network Ownership** — transferred to player during dribble for lag-free animation
3. **Remotes** — 6 events: `RequestPickup`, `RequestDrop`, `RequestShoot`, `RequestPass`, `BallOwnerChanged`, `ScoreNotify`
4. **Client** — input → local feedback (animation, UI) → fire remote to server

---

## 📊 Tuning Constants

Edit `src/shared/Constants.luau`:

```luau
-- Ball physics
BALL_SIZE = 1.8
BALL_DENSITY = 0.7
BALL_FRICTION = 0.3
BALL_ELASTICITY = 0.83

-- Shot accuracy system
SHOT_OSCILLATION_SPEED = 0.8      -- marker bounces 0.8x per second
SWEET_SPOT_CENTER = 0.70          -- optimal release at 70% from bottom
SWEET_SPOT_WIDTH = 0.16           -- green zone spans ±8% around center

-- Stamina
MAX_STAMINA = 100
STAMINA_DRAIN_RATE = 20           -- sprint drain/s
DRIBBLE_STAMINA_DRAIN = 5         -- extra drain/s while holding
STAMINA_REGEN_RATE = 15           -- regen/s while idle

-- Hoop
HOOP_POSITION = Vector3.new(0, 0, -50)
RIM_HEIGHT = 10
RIM_RADIUS = 1.8

-- Pass
PASS_POWER = 50
PASS_RANGE = 60
```

---

## 🛠️ Setup & Build

### Requirements
- **Rojo 7.7.0-rc.1** (managed by Aftman)
- **Roblox Studio** (latest)

### Build & Run

```bash
# Build place file
npx rojo build -o "BasketBall - Prototype.rbxlx"

# Or use Aftman
aftman install
rojo build -o "BasketBall - Prototype.rbxlx"
```

### Live Sync with Studio

```bash
rojo serve
```

Then in Roblox Studio:
1. Open `BasketBall - Prototype.rbxlx`
2. In **File > Rojo > Connect** → connect to `localhost:34872`
3. Edit code; changes sync live into Studio

---

## 🎯 Mekanik Game

### Pickup/Drop (E)
- Validasi: ball bebas, player dalam range (8 studs)
- Ball dilekatkan ke hand via `AlignPosition` constraint
- Network ownership ditransfer ke player
- Dribble animation dimulai

### Shoot (LMB)
1. **Charge** — tahan LMB, marker bergerak naik-turun
2. **Sweet Spot** — green zone 62%-78%, marker hijau = akurat
3. **Release** — lepas LMB:
   - Arm winddup → snap release → follow-through
   - Jump otomatis
   - Accuracy dihitung dari posisi marker
   - Server: arc velocity computed, bola diluncurkan ke ring
4. **Scoring** — bola masuk top→bottom dalam 1.5s = score +1

### Pass (F)
- Target: pemain terdekat dalam arah kamera, max range 60 studs
- Arm animation: quick extend → return
- Ball diluncurkan dengan fixed power ke target

### Sprint (LeftShift)
- Humanoid speed 16 → 28 stud/s
- Stamina drain 20/s
- Stop otomatis saat stamina habis

---

## 🎨 Visual Design

### UI Colors
- **Stamina Green** — `RGB(0, 210, 0)`
- **Stamina Red** — `RGB(255, 0, 0)`
- **Sweet Spot Green** — `RGB(50, 220, 80)`
- **Power Marker** — White (off) / Green (in sweet spot)

### Animation Easing
- **Fast** — 0.18s Quad.Out
- **Medium** — 0.32s Quad.InOut
- **Snap** — 0.10s Quart.Out

---

## 🔧 Teknologi

- **Rojo 7.7.0-rc.1** — file-based Roblox development
- **Luau** — scripting language (.luau files)
- **TweenService** — smooth arm motor animations
- **Motor6D** — articulation via C0 manipulation
- **AlignPosition/AlignOrientation** — ball attachment physics
- **BillboardGui** — world-space UI (stamina bar)
- **ScreenGui** — 2D HUD (shot power, score)

---

## 📝 Development Notes

### Code-Based Animations (No Animation IDs)
- All arm animations via `Motor6D.C0` tweening
- Poses defined as CFrame offsets in `Poses` table
- Multiplied onto original C0 to preserve default stance

### Ball Physics & Trajectory
- Server calculates arc (parabolic path) to ring center
- Arc height scales with distance: `hDist * 0.28 + ARC_HEIGHT_BONUS`
- Random XZ offset applied based on inaccuracy (0% accuracy → max 6 studs miss)

### Dribble & Held Ball
- Ball `CanCollide = false` while held
- AttachmentPosition on ball oscillates sine-wave
- AlignPosition drives smooth following of hand
- Client has network ownership for lag-free visual feedback

### Two-Zone Scoring
- Prevents scoring from sides or below rim
- Top zone: disc at rim top (Y=10)
- Bottom zone: disc 1.5 studs below
- Must touch top → then bottom within 1.5s window

---

## 🚀 Future Enhancements

- [ ] Multiplayer support (2v2, 3v3)
- [ ] Full-court second ring
- [ ] In-game scoreboard
- [ ] Stat tracking (attempts, makes, assists)
- [ ] Ball curves/spin physics
- [ ] Defender logic (AI or player-controlled)
- [ ] Sound effects & ambient music
- [ ] Custom player cosmetics

---

## 📧 Feedback

Jika ada bug atau saran improvement, buat issue atau diskusikan lebih lanjut!

---

Generated dengan ❤️ menggunakan **Rojo + Luau** | Last updated: 2026-04-05
