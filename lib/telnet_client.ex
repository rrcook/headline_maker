defmodule TelnetClient do
  @moduledoc """
  Simple Telnet client using :gen_tcp.
  """
  require Logger


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

  @doc """
  Waits for data matching one of the given patterns (POSIX regex).

  Patterns may be plain strings or `{tag, string}` tuples. Returns
  `{:ok, matched_binary}` for a plain pattern or `{:ok, {tag, matched_binary}}`
  for a tagged pattern. Returns `{:error, :timeout}` if no match arrives
  before the timeout.

  Options:
    - `idle_timeout`  - ms to wait for the next TCP chunk (default 10_000)
    - `total_timeout` - overall time limit in ms, or `:infinity` (default)
  """
  @type pattern :: String.t() | {term(), String.t()}
  @spec expect(port(), pattern | [pattern], keyword()) ::
          {:ok, binary()} | {:ok, {term(), binary()}} | {:error, term()}
  def expect(socket, patterns, opts \\ []) do
    idle_timeout = Keyword.get(opts, :idle_timeout, 10_000)
    total_timeout = Keyword.get(opts, :total_timeout, :infinity)

    compiled = patterns |> List.wrap() |> compile_patterns()

    deadline =
      case total_timeout do
        :infinity -> :infinity
        ms -> :erlang.monotonic_time(:millisecond) + ms
      end

    do_expect(socket, compiled, <<>>, idle_timeout, deadline)
  end

  defp compile_patterns(patterns) do
    Enum.map(patterns, fn
      {tag, pat} ->
        {:ok, mp} = :re.compile(pat, [:unicode])
        {tag, mp}
      pat ->
        {:ok, mp} = :re.compile(pat, [:unicode])
        mp
    end)
  end

  defp do_expect(socket, patterns, buffer, idle_timeout, deadline) do
    remaining =
      case deadline do
        :infinity -> idle_timeout
        d -> min(idle_timeout, max(0, d - :erlang.monotonic_time(:millisecond)))
      end

    if remaining <= 0 do
      Logger.debug("timeout with #{buffer}")
      {:error, :timeout}
    else
      case :gen_tcp.recv(socket, 0, remaining) do
        {:ok, data} ->
          new_buffer = buffer <> data
          case match_patterns(new_buffer, patterns) do
            {:match, result} -> {:ok, result}
            :nomatch -> do_expect(socket, patterns, new_buffer, idle_timeout, deadline)
          end

          {:error, :timeout} ->
          Logger.debug("timeout with #{buffer}")
          {:error, :timeout}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp match_patterns(data, patterns) do
    Enum.find_value(patterns, :nomatch, fn
      {tag, mp} ->
        case :re.run(data, mp, [{:capture, :all, :binary}]) do
          {:match, [full | _]} -> {:match, {tag, full}}
          :nomatch -> false
        end

      mp ->
        case :re.run(data, mp, [{:capture, :all, :binary}]) do
          {:match, [full | _]} -> {:match, full}
          :nomatch -> false
        end
    end)
  end
end
