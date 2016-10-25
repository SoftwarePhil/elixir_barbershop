defmodule BarberShop.Barber do
@moduledoc """
  This module acts like a barber, it takes a customer,
  and cuts their hair.

  1. A barber can only cut one customer's hair at a time
  2. After a barber has finished cutting a customer's hair
  they go to 'sleep'
"""

#have to think more about how to handle barbers
##we know what who the next customer is,
##we don't know which barber is free,
##I think that should be tracked by
##ShopServer, this  module will act like shop does

alias BarberShop.Server, as: Server

  def init(time, id) do
    spawn(__MODULE__, :cuthair, [time, id])
    #Server.next_haircut
  end

  def cuthair(time, id) do
    receive do
      {:customer, customer_id} ->
        IO.puts "barber #{id} cutting #{customer_id}'s hair"
        #send shop_pid, {:cutting, id}

        :timer.sleep(time)

        IO.puts "barber #{id} is done cutting #{customer_id}'s hair"
        #send shop_pid, {:cutting_done, id} # need a GenServer cast to set state to free again

        #this is conufsing because, when the haircut is done,
        #the server being send this busy barber,
        #the barber gets marked as being free in the servers list
        #by calling barber_done function
        Server.barber_done({self, :busy})
        Server.next_haircut

    after 1000 ->
      Server.next_haircut
    end

    cuthair(time, id)
  end

#find give next free barber a new customer
  def next_haircut(barber_list, customer_id) do
    next_haircut(barber_list, customer_id, [])
  end

  defp next_haircut([_barber = {pid, :free}|t], customer_id, new_list) do
    send pid, {:customer, customer_id}
    {:ok, new_list ++ [{pid, :busy}] ++ t}
  end

  defp next_haircut([barber = {_pid, :busy}|t], customer_id, new_list) do
    next_haircut(t, customer_id, new_list ++ [barber])
  end

  defp next_haircut([], _customer_id, new_list) do
    {:fail, new_list}
  end

#used to mark a barber done after they complete a haircut
  def barber_done(barber_list, barber) do
    barber_done(barber_list, barber, [])
  end

  defp barber_done([{pid, :busy}|t], _barber = {pid, :busy}, new_list) do
    new_list ++ [{pid, :free}] ++ t
  end

  defp barber_done([h | t], barber, new_list) do
    barber_done(t, barber, new_list ++ [h])
  end

end
