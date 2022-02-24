defmodule MyGenServer do
  def start(callback_module) do
    spawn(fn -> loop(callback_module, callback_module.init) end)
  end

  defp loop(callback_module, state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, state)

        send(caller, {:response, response})

        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(request, state)

        loop(callback_module, new_state)
    end
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} ->
        response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end
end

defmodule KeyValueStore do
  def start do
    MyGenServer.start(KeyValueStore)
  end

  def get(pid, key) do
    MyGenServer.call(pid, {:get, key})
  end

  def put(pid, key, value) do
    MyGenServer.cast(pid, {:put, key, value})
  end

  def init do
    %{}
  end

  def handle_call({:get, key}, state) do
    {Map.get(state, key), state}
  end

  def handle_cast({:put, key, value}, state) do
    Map.put(state, key, value)
  end
end

pid = KeyValueStore.start()

KeyValueStore.put(pid, "key", "value")

value = KeyValueStore.get(pid, "key")
IO.inspect(value)
