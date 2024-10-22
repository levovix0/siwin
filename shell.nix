{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
	nativeBuildInputs = with pkgs.buildPackages; [
		clang
		gnumake
		pkg-config
		bear
		
		xorg.libX11
		xorg.libXcursor.dev
		xorg.libXrender
		xorg.libXext
		libxkbcommon
		libGL.dev
		wayland
		wayland-protocols
		wayland-scanner.dev
	];
}
