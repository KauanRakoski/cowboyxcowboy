# Top-Down Multiplayer Shooter

A prototype top-down shooter developed in Godot 4, focused on P2P multiplayer networking and gameplay synchronization.

## Features
* **Online Multiplayer:** Connect with friends via IP using Godot's ENet system.
* **Real-time Sync:** Synchronized movement, shooting, animations, and health states across all clients.
* **Lobby System:** Clean UI to host and join matches.

## How to Play
You can play over a local network (LAN) or over the internet using a virtual LAN like LogMeIn Hamachi.

**To Host a game:**
1. Open the game and click **Host**.
2. Share your IPv4 address (or Hamachi IP) with your friend.
3. Wait in the lobby for the connection.

**To Join a game:**
1. Open the game and click **Join**.
2. Enter the Host's IP address.
3. You will automatically spawn in the arena once connected.

## Built With
* [Godot Engine 4](https://godotengine.org/)
* GDScript