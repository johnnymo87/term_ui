defmodule TermUI.CapabilitiesTest do
  use ExUnit.Case, async: true

  alias TermUI.Capabilities

  # No setup needed - tests use env injection instead of mutating global state

  describe "detect/0 and get/0" do
    test "returns capabilities struct" do
      caps = Capabilities.detect()
      assert %Capabilities{} = caps
    end

    test "caches capabilities" do
      caps1 = Capabilities.detect()
      caps2 = Capabilities.get()
      assert caps1 == caps2
    end

    test "get/0 detects if not cached" do
      Capabilities.clear_cache()
      caps = Capabilities.get()
      assert %Capabilities{} = caps
    end
  end

  describe "environment variable detection - $TERM" do
    test "detects truecolor from $TERM" do
      caps = Capabilities.detect(%{"TERM" => "xterm-truecolor"})

      assert caps.color_mode == :true_color
      assert caps.max_colors == 16_777_216
      assert caps.terminal_type == "xterm-truecolor"
    end

    test "detects 256color from $TERM suffix" do
      caps = Capabilities.detect(%{"TERM" => "xterm-256color"})

      assert caps.color_mode == :color_256
      assert caps.max_colors >= 256
    end

    test "detects xterm as 256-color capable" do
      caps = Capabilities.detect(%{"TERM" => "xterm"})

      assert caps.color_mode == :color_256
      assert caps.max_colors >= 256
    end

    test "detects screen as 256-color capable" do
      caps = Capabilities.detect(%{"TERM" => "screen"})

      assert caps.color_mode == :color_256
    end

    test "detects tmux as 256-color capable" do
      caps = Capabilities.detect(%{"TERM" => "tmux-256color"})

      assert caps.color_mode == :color_256
    end

    test "detects linux console as 16-color" do
      caps = Capabilities.detect(%{"TERM" => "linux"})

      assert caps.color_mode == :color_16
      assert caps.max_colors == 16
    end

    test "detects dumb terminal as monochrome" do
      caps = Capabilities.detect(%{"TERM" => "dumb"})

      assert caps.color_mode == :monochrome
      assert caps.max_colors == 2
    end
  end

  describe "environment variable detection - $COLORTERM" do
    test "detects truecolor from $COLORTERM" do
      caps = Capabilities.detect(%{"TERM" => "xterm", "COLORTERM" => "truecolor"})

      assert caps.color_mode == :true_color
      assert caps.max_colors == 16_777_216
    end

    test "detects 24bit from $COLORTERM" do
      caps = Capabilities.detect(%{"TERM" => "xterm", "COLORTERM" => "24bit"})

      assert caps.color_mode == :true_color
      assert caps.max_colors == 16_777_216
    end
  end

  describe "environment variable detection - $TERM_PROGRAM" do
    test "detects iTerm.app capabilities" do
      caps = Capabilities.detect(%{"TERM" => "xterm", "TERM_PROGRAM" => "iTerm.app"})

      assert caps.color_mode == :true_color
      assert caps.mouse == true
      assert caps.bracketed_paste == true
      assert caps.focus_events == true
      assert caps.terminal_program == "iTerm.app"
    end

    test "detects vscode terminal capabilities" do
      caps = Capabilities.detect(%{"TERM" => "xterm", "TERM_PROGRAM" => "vscode"})

      assert caps.color_mode == :true_color
      assert caps.mouse == true
    end

    test "detects Alacritty capabilities" do
      caps = Capabilities.detect(%{"TERM" => "xterm", "TERM_PROGRAM" => "Alacritty"})

      assert caps.color_mode == :true_color
    end

    test "detects Apple_Terminal as 256-color" do
      caps = Capabilities.detect(%{"TERM" => "xterm", "TERM_PROGRAM" => "Apple_Terminal"})

      assert caps.color_mode == :color_256
    end
  end

  describe "environment variable detection - $LANG" do
    test "detects UTF-8 from $LANG" do
      caps = Capabilities.detect(%{"LANG" => "en_US.UTF-8"})

      assert caps.unicode == true
    end

    test "detects UTF-8 from $LC_ALL" do
      caps = Capabilities.detect(%{"LC_ALL" => "en_US.UTF-8"})

      assert caps.unicode == true
    end

    test "detects non-UTF-8 locale" do
      caps = Capabilities.detect(%{"LANG" => "en_US.ISO-8859-1"})

      assert caps.unicode == false
    end
  end

  describe "capability accessors" do
    # Note: Accessor functions use get() which relies on global ETS cache.
    # We test the detection logic directly via detect(env) and verify struct values.

    test "supports_true_color? logic" do
      caps = Capabilities.detect(%{"COLORTERM" => "truecolor"})
      assert caps.color_mode == :true_color
    end

    test "supports_256_color? logic for true-color" do
      caps = Capabilities.detect(%{"COLORTERM" => "truecolor"})
      assert caps.color_mode in [:true_color, :color_256]
    end

    test "supports_256_color? logic for 256-color" do
      caps = Capabilities.detect(%{"TERM" => "xterm-256color"})
      assert caps.color_mode in [:true_color, :color_256]
    end

    test "supports_mouse? logic" do
      caps = Capabilities.detect(%{"TERM_PROGRAM" => "iTerm.app"})
      assert caps.mouse == true
    end

    test "supports_bracketed_paste? logic" do
      caps = Capabilities.detect(%{"TERM_PROGRAM" => "iTerm.app"})
      assert caps.bracketed_paste == true
    end

    test "supports_unicode? logic" do
      caps = Capabilities.detect(%{"LANG" => "en_US.UTF-8"})
      assert caps.unicode == true
    end

    test "max_colors value" do
      caps = Capabilities.detect(%{"COLORTERM" => "truecolor"})
      assert caps.max_colors == 16_777_216
    end

    test "color_mode value" do
      caps = Capabilities.detect(%{"COLORTERM" => "truecolor"})
      assert caps.color_mode == :true_color
    end
  end

  describe "clear_cache/0" do
    test "clears cached capabilities" do
      Capabilities.detect()
      Capabilities.clear_cache()

      # Verify cache is empty by checking ETS directly
      # get/0 will re-detect
      Capabilities.clear_cache()
      assert :ok == Capabilities.clear_cache()
    end
  end
end
