defmodule SuperIssuer.Contract do
  use Ecto.Schema
  import Ecto.Changeset
  alias SuperIssuer.{Chain, Contract, Evidence, EvidenceHandler, ContractTemplate}
  alias SuperIssuer.Repo

  schema "contract" do
    field :addr, :string
    field :description, :string
    field :creater, :string
    field :init_params, :map
    belongs_to :chain, Chain
    belongs_to :contract_template, ContractTemplate
    has_many :evidence, Evidence
    timestamps()
  end
  @doc """
    handle is the func when init
  """
  def handle(
    %{type: "Evidence", creater: creater, addr: addr} = contract) do
    %{chain: chain} =
      preload(contract)

    {:ok, signers} =
      EvidenceHandler.get_signers(chain, creater, addr)
    init_params =
      %{evidenceSigners: signers}
    contract
    |> Map.put(:init_params, init_params)
  end

  def preload(contract) do
    Repo.preload(contract, [:chain, :contract_template])
  end

  def handle(contract, _init_params) do
    contract
    |> Map.put(:init_params, Poison.decode!(contract.init_params))
  end

  def get_all() do
    Repo.all(Contract)
  end
  def get_by_addr(addr) do
    Repo.get_by(Contract, addr: addr)
  end

  def get_by_id(id) do
    Repo.get_by(Contract, id: id)
  end
  def get_by_type(type) do
    Repo.all(Contract, type: type)
  end

  def get_by_description(item) do
    Repo.get_by(Contract, description: item)
  end

  def create(attrs \\ %{}) do
    %Contract{}
    |> Contract.changeset(attrs)
    |> Repo.insert()
  end

  def change(%Contract{} = ele, attrs) do
    ele
    |> changeset(attrs)
    |> Repo.update()
  end

  def changeset(%Contract{} = ele) do
    Contract.changeset(ele, %{})
  end

  @doc false
  def changeset(%Contract{} = contract, attrs) do
    contract
    |> cast(attrs, [:addr, :description, :creater, :init_params, :contract_template_id, :chain_id])
    |> unique_constraint(:description)
  end
end
