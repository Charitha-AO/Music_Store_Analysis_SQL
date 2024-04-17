/* Q1: Who is the senior most employee based on job title? */
SELECT employee_id,first_name,last_name,title,levels
FROM employee
ORDER BY levels DESC
LIMIT 1

/* Q2: Which countries have the most Invoices? */
--Using window fnction
SELECT DISTINCT billing_country,COUNT(*) OVER(PARTITION BY billing_country) as Count_of_Invoices
FROM invoice
ORDER BY billing_country DESC
--Using Group By clause
select billing_country,count(billing_country) as count_of_country from invoice
group by billing_country
order by billing_country desc

/* Q3: What are top 3 values of total invoice? */
SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals */
--Using window function
SELECT DISTINCT billing_city,SUM(total) OVER(PARTITION BY billing_city) AS total_invoice
FROM invoice
ORDER BY total_invoice DESC
LIMIT 1
--Using group by clause
select billing_city,sum(total) as total_invoice from invoice
group by billing_city
order by total_invoice desc
LIMIT 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
SELECT cust.customer_id,cust.first_name,cust.last_name,SUM(invoice.total) AS total_money_spent 
FROM invoice
JOIN customer cust ON cust.customer_id=invoice.customer_id
GROUP BY cust.customer_id
ORDER BY total_money_spent DESC
LIMIT 1

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
SELECT DISTINCT Customer.Email,Customer.first_name,customer.last_name 
FROM Customer
JOIN Invoice ON Customer.Customer_Id=Invoice.Customer_ID
JOIN Invoice_Line ON Invoice.Invoice_Id=Invoice_line.Invoice_Id
JOIN Track ON Invoice_Line.Track_Id=Track.Track_Id
JOIN genre ON track.genre_id=Genre.Genre_Id
WHERE Genre.name LIKE 'Rock'
ORDER BY Customer.email

/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
SELECT Artist.Artist_Id,Artist.Name,COUNT(Artist.Artist_Id) AS Songs_Count
FROM Artist
JOIN Album ON Album.Artist_Id=Artist.Artist_Id
JOIN Track ON Track.Album_Id=Album.Album_Id
JOIN Genre ON Genre.Genre_Id=Track.Genre_Id
WHERE Genre.Name = 'Rock'
GROUP BY Artist.Artist_Id
ORDER BY Songs_Count DESC	
LIMIT 10

/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
SELECT Name,Milliseconds AS song_length 
FROM Track
WHERE Milliseconds > (SELECT AVG(Milliseconds) AS Avg_song_length 
					  FROM Track)
ORDER BY Milliseconds DESC

/* Q9: Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */
WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, 
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name,
SUM(il.unit_price*il.quantity) AS money_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */
WITH popular_genre_by_country AS (
    SELECT COUNT(il.quantity) AS purchase_count,
    c.country, g.genre_id,g.name
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON i.customer_id = c.customer_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.genre_id, g.name
)
SELECT purchase_count,country,genre_id,name
FROM popular_genre_by_country p
WHERE purchase_count = (
        SELECT MAX(purchase_count)
        FROM popular_genre_by_country
        WHERE country = p.country
)
--Using Window Function
with popular_genre_by_country as(
	select Count(invoice_Line.quantity) as purchase_count,Customer.country,genre.genre_id,genre.name,
    Row_number() over(partition by customer.country) as row_no 
    FROM invoice_Line
    join invoice on invoice_Line.Invoice_Id=Invoice.Invoice_Id
    join customer on customer.customer_Id=invoice.Customer_Id
    join Track on Track.Track_Id=Invoice_Line.Track_Id
    join genre on Track.Genre_Id=Genre.Genre_Id
    Group by Customer.country,genre.genre_id,genre.name
    order by Customer.country asc,purchase_count desc
)
select * from popular_genre_by_country where row_no=1

/* Q11: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */
WITH cte AS(
SELECT Customer.customer_Id,Customer.First_Name,Customer.Last_Name,invoice.billing_country,
	SUM(invoice.total) AS money_spent,
	ROW_NUMBER() OVER(PARTITION BY invoice.billing_country ORDER BY SUM(invoice.total) DESC) AS rownumber
	FROM Customer
	JOIN invoice ON Customer.Customer_Id=invoice.Customer_Id
	GROUP BY Customer.customer_Id,Customer.First_Name,Customer.Last_Name,invoice.billing_country
	ORDER BY money_spent,rownumber DESC
)
SELECT * FROM cte WHERE rownumber=1