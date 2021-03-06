defmodule SuperIssuerWeb.AppController do
  alias SuperIssuer.{AppCenter, App, Chain, Contract, ContractTemplate, EvidenceHandler, WeidInteractor}
  use SuperIssuerWeb, :controller

  @resp_success %{
    error_code: 0,
    error_msg: "success",
    result: ""
  }

  @resp_failure %{
    error_code: 1,
    error_msg: "",
    result: ""
  }

  # +---------------+
  # | contracts api |
  # +---------------+

  @doc """
    [api]/contracts
  """
  def get_contracts(conn, params) do
    params
    |> StructTranslater.to_atom_struct()
    |> auth()
    |> do_get_contracts(conn)
  end

  def auth(%{app_id: id, secret_key: secret_key}) do
    with {:ok, app} <- App.handle_result(App.get_by_id(id)),
        true <- AppCenter.key_correct?(app, secret_key) do
        {:ok, app}
    else
      _ ->
        {:error, "incorrect app_id or secret_key"}
    end
  end
  def do_get_contracts({:ok, %{contracts: contracts}}, conn) do
    contracts_info = get_contracts_info(contracts)
    json(conn, contracts_info)
  end

  def do_get_contracts({:error, info}, conn) do
    payload =
      @resp_failure
      |> Map.put(:error_msg, info)
    json(conn, payload)
  end

  def get_contracts_info(contracts) do
    Enum.map(contracts, fn contract->
      contract
        = %{contract_template: c_tem}
        = Contract.preload(contract)
      funcs = ContractTemplate.get_funcs(c_tem)
      events = ContractTemplate.get_events(c_tem)
      %{}
      |> Map.put(:id, contract.id)
      |> Map.put(:init_params, contract.init_params)
      |> Map.put(:type,  c_tem.name)
      |> Map.put(:description, contract.description)
      |> Map.put(:funcs, funcs)
      |> Map.put(:events, events)
    end)
  end

  @doc """
    [api]/contract/func
  """
  def interact_with_contract(conn, params) do
    params_struct =  StructTranslater.to_atom_struct(params)
    params_struct
    |> auth()
    # |> has_contract_permission?(params_struct)
    |> do_interact_with_contract(params_struct, conn)
  end

  def do_interact_with_contract(
    {:ok, _app},
    %{contract_id: c_id, func: func_name, params: payload},
    conn) do
    # TODO: 优化
    %{chain: chain}
      = contract
      = c_id
        |> Contract.get_by_id()
        |> Contract.preload()
    payload_res =
      get_payload(chain, contract, func_name, payload)

    json(conn, payload_res)
  end

  def do_interact_with_contract({:error, info}, _params_struct, conn) do
    json(conn, %{error: info})
  end

  def get_payload(chain, contract, func_name, payload) do
    try do
      case contract.contract_template.name do
        "Evidence" ->
          case func_name do
            "newEvidence" ->
              {:ok, evi} =
                EvidenceHandler.new_evidence(
                  chain,
                  payload.signer,
                  contract,
                  payload.evidence)
              evi_struct = StructTranslater.struct_to_map(evi)

              Map.put(@resp_success, :result, evi_struct)
          end
      end
    catch
      error ->
        Map.put(@resp_failure, :result, inspect(error))
    end
  end

  # +----------+
  # | weid api |
  # +----------+

  def create_weid(conn, params) do
    params_struct =
      params
      |> StructTranslater.to_atom_struct()

    params_struct
    |> auth()
    |> has_weid_permission?()
    |> do_create_weid(params_struct, conn)
  end

  def has_weid_permission?({:ok, %{weid_permission: 1} = app}) do
    {:ok, app}
  end
  def has_weid_permission?({:ok, %{weid_permission: _others}}) do
    {:error, "this app is not allowed to use weid"}
  end
  def has_weid_permission?(others), do: others

  def do_create_weid({:ok, _app}, %{chain_id: chain_id}, conn) do
    chain = Chain.get_by_id(chain_id)
    {:ok, weid} = WeidInteractor.create_weid(chain)
    payload = Map.put(@resp_success, :result, weid)
    json(conn, payload)
  end

  def do_create_weid({:error, info}, _params_struct, conn) do
    json(conn, %{error: info})
  end

end
