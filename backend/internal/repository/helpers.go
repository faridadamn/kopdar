package repository

import "strconv"

// itoa converts an int to a string for use as a SQL parameter placeholder.
func itoa(i int) string {
	return strconv.Itoa(i)
}
