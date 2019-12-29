defmodule Boardr.Mocks do
  import Hammox

  defmock(Boardr.Mocks.Rules, for: Boardr.Rules)
  defmock(Boardr.Mocks.Rules.Factory, for: Boardr.Rules.Factory)

  def mock_rules_factory!(context) do
    set_mox_global(context)
    verify_on_exit!(context)

    expect(Boardr.Mocks.Rules.Factory, :get_rules, fn _name -> Boardr.Mocks.Rules end)
    Application.put_env(:boardr, :gaming, rules_factory: Boardr.Mocks.Rules.Factory)

    :ok
  end
end
