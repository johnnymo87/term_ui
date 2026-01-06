defmodule TermUI.Test.AssertionHelpers do
  @moduledoc """
  Common assertion helpers for TermUI tests.
  """

  import ExUnit.Assertions

  @doc """
  Asserts that a module exports a function with the given name and arity.

  This helper ensures the module is loaded before checking, which prevents
  flaky test failures when running with `async: true`. The BEAM's
  `function_exported?/3` only checks already-loaded modules - it does NOT
  load modules from disk even if they exist in `_build`.

  ## Examples

      assert_function_exported(MyModule, :my_function, 2)
      assert_function_exported(TermUI.Input.Raw, :poll, 2)
  """
  @spec assert_function_exported(module(), atom(), non_neg_integer()) :: true
  def assert_function_exported(module, function, arity) do
    assert Code.ensure_loaded?(module),
           "Module #{inspect(module)} could not be loaded"

    assert function_exported?(module, function, arity),
           "Expected #{inspect(module)} to export #{function}/#{arity}"
  end

  @doc """
  Asserts that a module exports all functions in a list.

  ## Examples

      assert_functions_exported(MyModule, [
        {:new, 0},
        {:poll, 2},
        {:mode, 1}
      ])
  """
  @spec assert_functions_exported(module(), [{atom(), non_neg_integer()}]) :: :ok
  def assert_functions_exported(module, functions) when is_list(functions) do
    assert Code.ensure_loaded?(module),
           "Module #{inspect(module)} could not be loaded"

    for {function, arity} <- functions do
      assert function_exported?(module, function, arity),
             "Expected #{inspect(module)} to export #{function}/#{arity}"
    end

    :ok
  end
end
