const std = @import("std");
const SDL = @cImport({
    @cInclude("SDL2/SDL.h");
});
const ReSid = @import("resid");

const Sid = ReSid.Sid;
const DumpPlayer = ReSid.DumpPlayer;
const MixingDumpPlayer = ReSid.MixingDumpPlayer;
const WavLoader = ReSid.WavLoader;
const WavData = ReSid.WavData;

/// Sound effect types supported by the game
pub const SoundEffectType = enum {
    ExplosionSmall,
    ExplosionBig,
    ExplosionHuge,
    Weapon1Fired,
    Weapon2Fired,
    Collectible,
    ShieldActivated,
};

/// Background thread function that continuously updates the music player
fn playerThreadFunc(player: *MixingDumpPlayer) !void {
    while (player.isPlaying()) {
        if (!player.update()) {
            player.stop();
        }
        std.time.sleep(35 * std.time.ns_per_ms);
    }
}

pub const SoundManager = struct {
    player: MixingDumpPlayer,
    player_thread: std.Thread,

    // Each sound effect has its own dedicated WAV file
    wav_explosion_small: WavData,
    wav_explosion_big: WavData,
    wav_explosion_huge: WavData,
    wav_weapon1_fired: WavData,
    wav_weapon2_fired: WavData,
    wav_collectible: WavData,
    wav_shield_activated: WavData,

    is_playing: bool,
    allocator: std.mem.Allocator,
    audio_device: SDL.SDL_AudioDeviceID,

    // Initialize the SoundManager with background music and sound effects.
    // Returns null if audio initialization fails
    // (game should continue without sound).
    pub fn init(allocator: std.mem.Allocator) ?*SoundManager {

        // Create a Sid instance and configure it
        var sid = Sid.init("1st-shot-audio") catch |err| {
            std.debug.print("[SOUND] Failed to init SID: {}\n", .{err});
            return null;
        };
        errdefer sid.deinit();

        // Create a DumpPlayer instance
        const dump_player = DumpPlayer.init(allocator, sid) catch {
            sid.deinit();
            return null;
        };

        // Wrap it in a MixingDumpPlayer
        var player = MixingDumpPlayer.init(allocator, dump_player) catch {
            sid.deinit();
            return null;
        };
        errdefer player.deinit();

        // Load SID dump for background music
        player.loadDmp("assets/audio/cnii.dmp") catch {
            player.deinit();
            sid.deinit();
            return null;
        };

        // Load WAV files - one for each sound effect type
        var wav_explosion_small = WavLoader.load(
            allocator,
            "assets/audio/explosion1.wav",
        ) catch |err| {
            std.debug.print(
                "[SOUND] Failed to load explosion1.wav: {}\n",
                .{err},
            );
            player.deinit();
            sid.deinit();
            return null;
        };
        errdefer wav_explosion_small.deinit();

        var wav_explosion_big = WavLoader.load(
            allocator,
            "assets/audio/explosion2.wav",
        ) catch |err| {
            std.debug.print(
                "[SOUND] Failed to load explosion2.wav: {}\n",
                .{err},
            );
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        };
        errdefer wav_explosion_big.deinit();

        var wav_explosion_huge = WavLoader.load(
            allocator,
            "assets/audio/explosion3.wav",
        ) catch |err| {
            std.debug.print(
                "[SOUND] Failed to load explosion3.wav: {}\n",
                .{err},
            );
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        };
        errdefer wav_explosion_huge.deinit();

        var wav_weapon1_fired = WavLoader.load(
            allocator,
            "assets/audio/shoot1.wav",
        ) catch |err| {
            std.debug.print(
                "[SOUND] Failed to load explosion1.wav for weapon: {}\n",
                .{err},
            );
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        };
        errdefer wav_weapon1_fired.deinit();

        var wav_weapon2_fired = WavLoader.load(
            allocator,
            "assets/audio/shoot2.wav",
        ) catch |err| {
            std.debug.print(
                "[SOUND] Failed to load explosion1.wav for weapon: {}\n",
                .{err},
            );
            wav_weapon1_fired.deinit();
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        };
        errdefer wav_weapon1_fired.deinit();

        var wav_collectible = WavLoader.load(
            allocator,
            "assets/audio/collect.wav",
        ) catch |err| {
            std.debug.print(
                "[SOUND] Failed to load explosion2.wav for collectible: {}\n",
                .{err},
            );
            wav_weapon2_fired.deinit();
            wav_weapon1_fired.deinit();
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        };
        errdefer wav_collectible.deinit();

        var wav_shield_activated = WavLoader.load(
            allocator,
            "assets/audio/shield-activation.wav",
        ) catch |err| {
            std.debug.print(
                "[SOUND] Failed to load explosion3.wav for shield: {}\n",
                .{err},
            );
            wav_collectible.deinit();
            wav_weapon2_fired.deinit();
            wav_weapon1_fired.deinit();
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        };
        errdefer wav_shield_activated.deinit();

        // Initialize SDL audio
        if (SDL.SDL_Init(SDL.SDL_INIT_AUDIO) < 0) {
            wav_shield_activated.deinit();
            wav_collectible.deinit();
            wav_weapon2_fired.deinit();
            wav_weapon1_fired.deinit();
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        }
        errdefer SDL.SDL_Quit();

        // Allocate on heap and initialize (without thread yet)
        const result = allocator.create(SoundManager) catch {
            SDL.SDL_Quit();
            wav_shield_activated.deinit();
            wav_collectible.deinit();
            wav_weapon2_fired.deinit();
            wav_weapon1_fired.deinit();
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            player.deinit();
            sid.deinit();
            return null;
        };

        result.* = SoundManager{
            .player = player,
            .player_thread = undefined, // Will be set below
            .wav_explosion_small = wav_explosion_small,
            .wav_explosion_big = wav_explosion_big,
            .wav_explosion_huge = wav_explosion_huge,
            .wav_weapon1_fired = wav_weapon1_fired,
            .wav_weapon2_fired = wav_weapon2_fired,
            .wav_collectible = wav_collectible,
            .wav_shield_activated = wav_shield_activated,
            .is_playing = true,
            .allocator = allocator,
            .audio_device = undefined, // Will be set below
        };

        // NOW set up SDL audio with the HEAP pointer
        var spec = SDL.SDL_AudioSpec{
            .freq = sid.getSamplingRate(),
            .format = SDL.AUDIO_S16SYS,
            .channels = 1,
            .samples = 4096,
            .callback = &DumpPlayer.sdlAudioCallback,
            .userdata = @ptrCast(&result.player.dump_player), // NOW points to heap!
        };

        const dev = SDL.SDL_OpenAudioDevice(null, 0, &spec, null, 0);
        if (dev == 0) {
            SDL.SDL_Quit();
            wav_shield_activated.deinit();
            wav_collectible.deinit();
            wav_weapon2_fired.deinit();
            wav_weapon1_fired.deinit();
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            result.player.deinit();
            sid.deinit();
            allocator.destroy(result);
            return null;
        }

        result.audio_device = dev;

        // Enable external updates (we control buffer filling)
        result.player.updateExternal(true);

        // Start SDL audio
        SDL.SDL_PauseAudioDevice(dev, 0);

        // Start playback
        result.player.play();

        // Now spawn thread with pointer to the heap-allocated player
        result.player_thread = std.Thread.spawn(.{}, playerThreadFunc, .{&result.player}) catch {
            SDL.SDL_CloseAudioDevice(dev);
            SDL.SDL_Quit();
            wav_shield_activated.deinit();
            wav_collectible.deinit();
            wav_weapon2_fired.deinit();
            wav_weapon1_fired.deinit();
            wav_explosion_huge.deinit();
            wav_explosion_big.deinit();
            wav_explosion_small.deinit();
            result.player.deinit();
            sid.deinit();
            allocator.destroy(result);
            return null;
        };

        return result;
    }

    /// Clean up all sound resources
    pub fn deinit(self: *SoundManager) void {
        std.debug.print("[SOUND] Shutting down SoundManager...\n", .{});

        // Stop playback
        self.player.stop();
        self.is_playing = false;

        // Wait for thread to finish
        self.player_thread.join();

        // Stop SDL audio
        SDL.SDL_PauseAudioDevice(self.audio_device, 1);
        SDL.SDL_CloseAudioDevice(self.audio_device);
        SDL.SDL_Quit();

        // Clean up all WAV data
        self.wav_shield_activated.deinit();
        self.wav_collectible.deinit();
        self.wav_weapon2_fired.deinit();
        self.wav_weapon1_fired.deinit();
        self.wav_explosion_huge.deinit();
        self.wav_explosion_big.deinit();
        self.wav_explosion_small.deinit();

        // Clean up player
        self.player.deinit();

        std.debug.print("[SOUND] SoundManager shutdown complete\n", .{});
    }

    /// Trigger a sound effect by type
    pub fn triggerSound(self: *SoundManager, effect_type: SoundEffectType) void {
        // Get the WAV data for this specific effect type
        const wav_data = switch (effect_type) {
            .ExplosionSmall => &self.wav_explosion_small,
            .ExplosionBig => &self.wav_explosion_big,
            .ExplosionHuge => &self.wav_explosion_huge,
            .Weapon1Fired => &self.wav_weapon1_fired,
            .Weapon2Fired => &self.wav_weapon2_fired,
            .Collectible => &self.wav_collectible,
            .ShieldActivated => &self.wav_shield_activated,
        };

        // Add the WAV source to the mixer
        self.player.addWavSource(wav_data.pcm_data, wav_data.num_channels) catch |err| {
            std.debug.print("[SOUND] Failed to trigger sound {}: {}\n", .{ effect_type, err });
        };
    }
};
