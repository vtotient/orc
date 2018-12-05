import data_transmition as d

while True:
	try:
		d.get_data()
	except:
		print("get_data excepted")

	try:
		print("temp:", d.get_temp())
		print("total:", d.get_counter())
		print("state count:",d.get_state_counter())
		print("state:",d.get_state())
		x = d.get_err_code()
		print("error:", x)
		print("\n")
	except:
		print("Can't fetch data to display, trying again...")