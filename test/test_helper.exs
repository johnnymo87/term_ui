# Conditionally exclude tests that require terminal and OTP 28+
terminal_available? =
  case :io.getopts(:standard_io) do
    {:ok, opts} -> Keyword.has_key?(opts, :terminal)
    _ -> false
  end

raw_mode_available? = function_exported?(:shell, :start_interactive, 1)

excludes =
  if terminal_available? and raw_mode_available? do
    []
  else
    [:requires_terminal]
  end

# Start Theme server under a supervisor so it survives test process shutdowns.
# This prevents flaky failures where async tests race with Theme's ETS table
# being deleted when the test process that started it exits.
{:ok, _sup} =
  Supervisor.start_link(
    [{TermUI.Theme, [theme: :dark, name: TermUI.Theme]}],
    strategy: :one_for_one,
    name: TermUI.TestSupport.Supervisor
  )

ExUnit.start(exclude: excludes)
