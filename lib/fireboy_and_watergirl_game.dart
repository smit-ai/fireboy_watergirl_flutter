import 'dart:async';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fireboy_and_watergirl/misc/jump_button.dart';
import 'package:fireboy_and_watergirl/providers/game_provider.dart';
import 'package:fireboy_and_watergirl/providers/player_provider.dart';
import 'package:fireboy_and_watergirl/characters/fireboy/fireboy.dart';
import 'package:fireboy_and_watergirl/characters/watergirl/watergirl.dart';
import 'package:fireboy_and_watergirl/scenes/level_1.dart';
import 'package:fireboy_and_watergirl/backgrounds/background.dart';
import 'package:fireboy_and_watergirl/config/audio/audio_manager.dart';
import 'package:fireboy_and_watergirl/config/utils/check_devices.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class FireBoyAndWaterGirlGame extends FlameGame with RiverpodGameMixin, KeyboardEvents, HasCollisionDetection {
  
  late JoystickComponent joystick;  
  late JumpButton jumpButton;
  FireboyAnimation? fireBoy;  
  WaterGirlAnimation? waterGirl;
  LevelOneSprite? level;

  double baseZoom = 1.5;  // Zoom base
  double minZoom = 1.0;  // Minimum permitted zoom
  double maxZoom = 4.5;  // Maximum allowed zoom
  double maxDistance = 2500; // Maximum distance between characters before zoom out

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  Future<void> startGame() async {
    debugMode = kDebugMode;
    level?.disposeLevel();
    clearWorld();
    AudioManager.playMusicLevel();
    final gameOnline = ref.read(providerGameStart).asData?.value;
    final player = ref.read(providerPlayer);
    final world = FireboyAndWaterGirlWorld();
    final background = BackgroundOneSprite();
    
    level = LevelOneSprite();
    fireBoy = FireboyAnimation();
    waterGirl = WaterGirlAnimation();
    camera = CameraComponent(
      world: world,
      viewport: MaxViewport(),
    );
      
    await addAll([world, camera]);

    if( CheckDevices.isMobile ) {
      await _addJoystick(); 
    }
    await world.addAll([
      background,
      level!,
      fireBoy!,
      waterGirl!
    ]);   


    // The camera follows Fireboy
    if( gameOnline?.isOnline == true ) {
      if(player.character == 'fireboy') {
        camera.follow(fireBoy!, maxSpeed: 300);
        if( CheckDevices.isMobile ) {
          fireBoy?.joystick = joystick;
        }
      } else {
        camera.follow(waterGirl!, maxSpeed: 300);
        if( CheckDevices.isMobile ) {
          waterGirl?.joystick = joystick;
        }
      }
      return;
    }

    camera.follow(fireBoy!, maxSpeed: 300);
    if( CheckDevices.isMobile ) {
      fireBoy?.joystick = joystick;
    }
  }

  void clearWorld() {
    // Limpiamos el world por completo
    removeAll(world.children);

    // Limpiamos la viewport de la camera
    removeAll(camera.viewport.children);

    // Reiniciamos instancias
    fireBoy = null;
    waterGirl = null;
    level = null;
  }


  Future<void> _addJoystick() async {
    final gameOnline = ref.read(providerGameStart).asData?.value;
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: await loadSprite('joystick/controller_position.png'),
        size: Vector2.all(50),
      ),
      background: SpriteComponent(
        sprite: await loadSprite('joystick/controller_radius.png'),
        size: Vector2.all(100),
      ),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
    );
    final player = ref.read(providerPlayer);
    final character = player.character == 'fireboy' ? fireBoy! : waterGirl!;
    jumpButton = JumpButton(gameOnline?.isOnline == true ? character : fireBoy!);    
    camera.viewport.add(joystick);
    camera.viewport.add(jumpButton);
  }

  

  @override
  void update(double dt) {
    super.update(dt);
    // AudioManager.stopMusicLevel();
    if( level == null ) return;

    if( level is LevelOneSprite ) {
      if( level!.levelComplete ) return;
    }

    // Adjust the zoom according to the distance between FireBoy and Watergirl
    final distance = (fireBoy!.position - waterGirl!.position).length;
    final zoomFactor = (1 - (distance / maxDistance)).clamp(0.0, 1.0);

    camera.viewfinder.zoom =
        (minZoom + (baseZoom - minZoom) * zoomFactor).clamp(minZoom, maxZoom);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final gameStart = ref.read(providerGameStart).asData?.value;
    final player = ref.read(providerPlayer);

    if( gameStart?.isOnline == true ){
      if( player.character == 'fireboy' ) {
        fireBoy?.onKeyEvent(event, keysPressed);
      } else {
        waterGirl?.onKeyEvent(event, keysPressed);
      }
      return super.onKeyEvent(event, keysPressed);
    }

    fireBoy?.onKeyEvent(event, keysPressed);
    waterGirl?.onKeyEvent(event, keysPressed);
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onDispose() {
    AudioManager.stopMusicLevel();
    AudioManager.stopPlayIntroMusic();
    super.onDispose();
  }
}

class FireboyAndWaterGirlWorld extends World {}


