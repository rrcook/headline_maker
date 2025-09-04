defmodule TelnetClient do
  @moduledoc """
  Simple Telnet client using :gen_tcp.
  """

  @default_port 23

  @spec open(String.t(), integer()) :: {:ok, port()} | {:error, term()}
  def open(host, port \\ @default_port) do
    :gen_tcp.connect(
      String.to_charlist(host),
      port,
      [:binary, active: false, packet: :raw]
    )
  end

  @spec close(port()) :: :ok
  def close(socket) do
    :gen_tcp.close(socket)
  end

  @spec send(port(), String.t()) :: :ok | {:error, term()}
  def send(socket, data) do
    :gen_tcp.send(socket, data)
  end

  @spec receive(port(), integer()) :: {:ok, binary()} | {:error, term()}
  def receive(socket, timeout \\ 1000) do
    recv(socket, [], timeout)
  end

  def recv(socket, bs, timeout) do
    case :gen_tcp.recv(socket, 0, timeout) do
      {:ok, b} ->
          recv(socket, [bs, b], timeout);
      {:error, :closed} ->
          {:ok, :erlang.list_to_binary(bs)}
      {:error, :timeout} ->
          {:ok, :erlang.list_to_binary(bs)}
    end
  end

end
