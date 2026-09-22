const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Database Connection
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});


const initializeDB = async () => {
    try {
        await pool.query(`ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255);`);
        await pool.query(`
            CREATE TABLE IF NOT EXISTS sale_items (
                item_id SERIAL PRIMARY KEY,
                invoice_id INTEGER REFERENCES sales_invoices(invoice_id) ON DELETE CASCADE,
                medicine_name VARCHAR(255) NOT NULL,
                quantity NUMERIC(10, 2) NOT NULL,
                mrp NUMERIC(10, 2) NOT NULL
            );
        `);
        
        
        await pool.query(`ALTER TABLE shop_inventory ALTER COLUMN quantity TYPE NUMERIC(10,2);`);
        await pool.query(`ALTER TABLE shop_inventory ADD COLUMN IF NOT EXISTS tablets_per_strip INTEGER DEFAULT 1;`); 
        await pool.query(`ALTER TABLE sale_items ALTER COLUMN quantity TYPE NUMERIC(10,2);`);

        
        await pool.query(`UPDATE shop_inventory SET tablets_per_strip = 1 WHERE tablets_per_strip IS NULL;`);
        
        console.log("✅ Database Verified & Ready!");
    } catch (err) {
        console.error("⚠️ DB Auto-Fix Error:", err.message);
    }
};
initializeDB();


app.get('/', (req, res) => {
    res.send('Medical Shop API is running...');
});


app.post('/api/register', async (req, res) => {
    const { owner_name, mobile, password, shop_name } = req.body;
    try {
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);
        const newOwner = await pool.query(
            'INSERT INTO shop_owners (owner_name, mobile, password_hash, shop_name) VALUES ($1, $2, $3, $4) RETURNING owner_id, owner_name, shop_name',
            [owner_name, mobile, password_hash, shop_name]
        );
        res.json({ success: true, message: "Account Created Successfully!", data: newOwner.rows[0] });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Registration Failed.' });
    }
});


app.post('/api/login', async (req, res) => {
    const { mobile, password } = req.body;
    try {
        const user = await pool.query('SELECT * FROM shop_owners WHERE mobile = $1', [mobile]);
        if (user.rows.length === 0) return res.status(401).json({ error: 'User not found!' });

        const validPassword = await bcrypt.compare(password, user.rows[0].password_hash);
        if (!validPassword) return res.status(401).json({ error: 'Incorrect Password!' });
        
        res.json({ success: true, message: "Login Successful!", owner_id: user.rows[0].owner_id });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Login Failed' });
    }
});




app.get('/api/dashboard-stats/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const totalMedicinesQuery = await pool.query('SELECT COUNT(*) FROM shop_inventory WHERE owner_id = $1', [owner_id]);
        const lowStockQuery = await pool.query('SELECT COUNT(*) FROM shop_inventory WHERE owner_id = $1 AND quantity < 10', [owner_id]);
        const salesQuery = await pool.query(
            `SELECT COALESCE(SUM(total_amount), 0) AS today_sales, COUNT(*) AS today_bills FROM sales_invoices WHERE owner_id = $1 AND sale_date >= CURRENT_DATE`,
            [owner_id]
        );
        
        const expiryQuery = await pool.query('SELECT expiry_date FROM shop_inventory WHERE owner_id = $1', [owner_id]);
        let nearExpiryCount = 0;
        const currentDate = new Date();
        expiryQuery.rows.forEach(item => {
            if (item.expiry_date && item.expiry_date.includes('/')) {
                const parts = item.expiry_date.split('/');
                if (parts.length === 2) {
                    const expDate = new Date(parseInt(parts[1]), parseInt(parts[0]), 0); 
                    const diffDays = Math.ceil((expDate - currentDate) / (1000 * 60 * 60 * 24));
                    if (diffDays > 0 && diffDays <= 90) nearExpiryCount++;
                }
            }
        });

        const ownerQuery = await pool.query('SELECT shop_name FROM shop_owners WHERE owner_id = $1', [owner_id]);
        
        res.json({
            success: true,
            data: {
                total_medicines: parseInt(totalMedicinesQuery.rows[0].count),
                low_stock: parseInt(lowStockQuery.rows[0].count),
                today_sales: parseFloat(salesQuery.rows[0].today_sales),
                today_bills: parseInt(salesQuery.rows[0].today_bills),
                near_expiry: nearExpiryCount,
                shop_name: ownerQuery.rows.length > 0 ? ownerQuery.rows[0].shop_name : 'Medical Store'
            }
        });
    } catch (err) {
        console.error("Dashboard Stats Error:", err.message);
        res.status(500).json({ error: 'Failed to fetch dashboard stats' });
    }
});


app.get('/api/inventory/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const inventory = await pool.query(
            'SELECT * FROM shop_inventory WHERE owner_id = $1 ORDER BY medicine_name ASC',
            [owner_id]
        );
        res.json({ success: true, data: inventory.rows });
    } catch (err) {
        console.error("Inventory Fetch Error:", err.message);
        res.status(500).json({ error: 'Failed to fetch inventory' });
    }
});


app.post('/api/new-sale', async (req, res) => {
    const { owner_id, cart_items, total_amount, customer_mobile, customer_name } = req.body;
    const client = await pool.connect(); 
    
    try {
        await client.query('BEGIN'); 
        const invoiceNo = 'INV-' + Date.now();
        const finalName = (customer_name && customer_name.trim() !== '') ? customer_name : 'Walk-in Customer';

        
        const saleResult = await client.query(
            'INSERT INTO sales_invoices (invoice_no, owner_id, customer_name, customer_mobile, total_amount) VALUES ($1, $2, $3, $4, $5) RETURNING invoice_id',
            [invoiceNo, owner_id, finalName, customer_mobile || '', total_amount]
        );
        const invoiceId = saleResult.rows[0].invoice_id;

        
        for (let item of cart_items) {
            await client.query(
                'UPDATE shop_inventory SET quantity = quantity - $1 WHERE inventory_id = $2 AND owner_id = $3',
                [item.sell_quantity, item.inventory_id, owner_id]
            );

            await client.query(
                'INSERT INTO sale_items (invoice_id, medicine_name, quantity, mrp) VALUES ($1, $2, $3, $4)',
                [invoiceId, item.medicine_name, item.sell_quantity, item.mrp]
            );
        }

        
        await client.query('DELETE FROM shop_inventory WHERE quantity <= 0 AND owner_id = $1', [owner_id]);

        await client.query('COMMIT'); 
        res.json({ success: true, message: "Bill Generated Successfully!", invoice_no: invoiceNo });

    } catch (err) {
        await client.query('ROLLBACK'); 
        console.error("Sale Error:", err.message);
        res.status(500).json({ error: 'Failed to process sale' });
    } finally {
        client.release();
    }
});

app.get('/api/todays-bills/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const billsQuery = await pool.query(
            `SELECT invoice_id, invoice_no, customer_name, customer_mobile, total_amount, sale_date 
             FROM sales_invoices WHERE owner_id = $1 AND sale_date >= CURRENT_DATE ORDER BY sale_date DESC`,
            [owner_id]
        );

        const billsWithItems = [];
        for (let bill of billsQuery.rows) {
            const itemsQuery = await pool.query(
                `SELECT medicine_name, quantity FROM sale_items WHERE invoice_id = $1`,
                [bill.invoice_id]
            );
            billsWithItems.push({ ...bill, items: itemsQuery.rows });
        }

        res.json({ success: true, data: billsWithItems });
    } catch (err) {
        console.error("Todays Bills Error:", err.message);
        res.status(500).json({ error: 'Failed to fetch todays bills' });
    }
});

app.get('/api/near-expiry/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const inventory = await pool.query(
            'SELECT * FROM shop_inventory WHERE owner_id = $1',
            [owner_id]
        );
        
        const currentDate = new Date();
        
        const expiringMedicines = inventory.rows.filter(item => {
            if (item.expiry_date && item.expiry_date.includes('/')) {
                const parts = item.expiry_date.split('/');
                if (parts.length === 2) {
                    const expMonth = parseInt(parts[0]);
                    const expYear = parseInt(parts[1]);
                    const expDate = new Date(expYear, expMonth, 0);
                    const diffTime = expDate - currentDate;
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                    return diffDays > 0 && diffDays <= 90;
                }
            }
            return false;
        });

        res.json({ success: true, data: expiringMedicines });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Failed to fetch near expiry medicines' });
    }
});

app.get('/api/expired-medicines/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const inventory = await pool.query(
            'SELECT * FROM shop_inventory WHERE owner_id = $1',
            [owner_id]
        );
        
        const currentDate = new Date();
        
        const expiredMedicines = inventory.rows.filter(item => {
            if (item.expiry_date && item.expiry_date.includes('/')) {
                const parts = item.expiry_date.split('/');
                if (parts.length === 2) {
                    const expMonth = parseInt(parts[0]);
                    const expYear = parseInt(parts[1]);
                    const expDate = new Date(expYear, expMonth, 0);
                    const diffTime = expDate - currentDate;
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                    
                    return diffDays <= 0;
                }
            }
            return false;
        });

        res.json({ success: true, data: expiredMedicines });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Failed to fetch expired medicines' });
    }
});

app.delete('/api/delete-medicine/:inventory_id', async (req, res) => {
    const { inventory_id } = req.params;
    try {
        await pool.query('DELETE FROM shop_inventory WHERE inventory_id = $1', [inventory_id]);
        res.json({ success: true, message: "Medicine deleted successfully from inventory!" });
    } catch (err) {
        console.error("Delete Error:", err.message);
        res.status(500).json({ error: 'Failed to delete medicine' });
    }
});


app.get('/api/low-stock/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const inventory = await pool.query(
            'SELECT * FROM shop_inventory WHERE owner_id = $1 AND quantity < 10 ORDER BY quantity ASC',
            [owner_id]
        );
        res.json({ success: true, data: inventory.rows });
    } catch (err) {
        console.error("Low Stock Error:", err.message);
        res.status(500).json({ error: 'Failed to fetch low stock medicines' });
    }
});

app.get('/api/accounts-report/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        
        const todayRes = await pool.query(
            `SELECT COALESCE(SUM(total_amount), 0) AS total FROM sales_invoices WHERE owner_id = $1 AND sale_date >= CURRENT_DATE`, [owner_id]
        );
        
        const weekRes = await pool.query(
            `SELECT COALESCE(SUM(total_amount), 0) AS total FROM sales_invoices WHERE owner_id = $1 AND sale_date >= date_trunc('week', CURRENT_DATE)`, [owner_id]
        );
        
        const monthRes = await pool.query(
            `SELECT COALESCE(SUM(total_amount), 0) AS total FROM sales_invoices WHERE owner_id = $1 AND sale_date >= date_trunc('month', CURRENT_DATE)`, [owner_id]
        );
        
        const yearRes = await pool.query(
            `SELECT COALESCE(SUM(total_amount), 0) AS total FROM sales_invoices WHERE owner_id = $1 AND sale_date >= date_trunc('year', CURRENT_DATE)`, [owner_id]
        );
        
        const lifeRes = await pool.query(
            `SELECT COALESCE(SUM(total_amount), 0) AS total FROM sales_invoices WHERE owner_id = $1`, [owner_id]
        );

        res.json({
            success: true,
            data: {
                today: parseFloat(todayRes.rows[0].total),
                weekly: parseFloat(weekRes.rows[0].total),
                monthly: parseFloat(monthRes.rows[0].total),
                yearly: parseFloat(yearRes.rows[0].total),
                lifetime: parseFloat(lifeRes.rows[0].total)
            }
        });
    } catch (err) {
        console.error("Accounts Report Error:", err.message);
        res.status(500).json({ error: 'Failed to fetch accounts report' });
    }
});




app.post('/api/add-medicine', async (req, res) => {
    let { owner_id, inventory_id, medicine_name, batch_no, quantity, mrp, expiry_date, barcode, tablets_per_strip } = req.body;
    
    try {
        const cleanName = medicine_name ? medicine_name.trim() : '';
        const finalTps = parseInt(tablets_per_strip) > 0 ? parseInt(tablets_per_strip) : 1; 
        const finalMrp = parseFloat(mrp) || 0;
        const finalBatch = batch_no ? batch_no.trim() : '';
        const finalExpiry = expiry_date ? expiry_date.trim() : '';
        
        let targetId = inventory_id;

        console.log(`\n================================`);
        console.log(`📥 NEW REQUEST TO ADD/UPDATE MED`);
        console.log(`💊 Medicine: ${cleanName}`);
        console.log(`📦 Received Pack Size (Tabs): ${finalTps}`);
        console.log(`================================\n`);

        
        if (!targetId && cleanName) {
            const findMed = await pool.query(
                `SELECT inventory_id FROM shop_inventory 
                 WHERE owner_id = $1 
                   AND LOWER(TRIM(medicine_name)) = LOWER(TRIM($2))
                   AND COALESCE(batch_no, '') = $3
                   AND mrp = $4
                   AND COALESCE(expiry_date, '') = $5
                 LIMIT 1`,
                [owner_id, cleanName, finalBatch, finalMrp, finalExpiry]
            );
            if (findMed.rows.length > 0) targetId = findMed.rows[0].inventory_id;
        }

        if (targetId) {
            
            const updatedMedicine = await pool.query(
                `UPDATE shop_inventory 
                 SET quantity = quantity + $1, 
                     tablets_per_strip = $2
                 WHERE inventory_id = $3 RETURNING *`,
                [parseFloat(quantity) || 0, finalTps, targetId]
            );
            console.log(`✅ SUCCESS: DB UPDATED! New Pack Size = ${updatedMedicine.rows[0].tablets_per_strip}`);
            res.json({ success: true, message: "Stock & Pack Size Updated! 🔄", data: updatedMedicine.rows[0] });
        } else {
            
            const newMedicine = await pool.query(
                `INSERT INTO shop_inventory (owner_id, medicine_name, batch_no, quantity, mrp, expiry_date, barcode, tablets_per_strip) 
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
                [owner_id, cleanName, finalBatch, parseFloat(quantity) || 0, finalMrp, finalExpiry, barcode, finalTps]
            );
            console.log(`✅ SUCCESS: DB INSERTED! New Pack Size = ${newMedicine.rows[0].tablets_per_strip}`);
            res.json({ success: true, message: "New Medicine Batch Added! ✅", data: newMedicine.rows[0] });
        }
    } catch (err) {
        console.error("❌ Add Medicine Server Error:", err.message);
        res.status(500).json({ error: 'Failed to process medicine.' });
    }
});


app.get('/api/owner-profile/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const owner = await pool.query(
            'SELECT owner_name, mobile, shop_name FROM shop_owners WHERE owner_id = $1',
            [owner_id]
        );
        if (owner.rows.length === 0) {
            return res.status(404).json({ error: 'Owner not found' });
        }
        res.json({ success: true, data: owner.rows[0] });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
});


app.put('/api/update-profile/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    const { owner_name, mobile, shop_name } = req.body;
    try {
        const updatedOwner = await pool.query(
            'UPDATE shop_owners SET owner_name = $1, mobile = $2, shop_name = $3 WHERE owner_id = $4 RETURNING owner_name, mobile, shop_name',
            [owner_name, mobile, shop_name, owner_id]
        );
        
        if (updatedOwner.rows.length === 0) {
            return res.status(404).json({ error: 'Owner not found' });
        }

        res.json({ 
            success: true, 
            message: "Profile updated successfully!", 
            data: updatedOwner.rows[0] 
        });
    } catch (err) {
        console.error("Update Profile Error:", err.message);
        res.status(500).json({ error: 'Failed to update profile. Mobile number might already exist.' });
    }
});


app.get('/api/recent-bills/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    try {
        const billsQuery = await pool.query(
            `SELECT invoice_id, invoice_no, customer_name, customer_mobile, total_amount, sale_date 
             FROM sales_invoices 
             WHERE owner_id = $1 AND sale_date >= CURRENT_DATE - INTERVAL '15 days'
             ORDER BY sale_date DESC`,
            [owner_id]
        );

        const billsWithItems = [];
        for (let bill of billsQuery.rows) {
            
            const itemsQuery = await pool.query(
                `SELECT s.item_id, s.medicine_name, s.quantity, s.mrp, 
                        COALESCE((SELECT tablets_per_strip FROM shop_inventory WHERE medicine_name = s.medicine_name AND owner_id = $2 LIMIT 1), 1) as tps
                 FROM sale_items s 
                 WHERE s.invoice_id = $1`,
                [bill.invoice_id, owner_id]
            );
            billsWithItems.push({ ...bill, items: itemsQuery.rows });
        }
        res.json({ success: true, data: billsWithItems });
    } catch (err) {
        console.error("Recent Bills Error:", err.message);
        res.status(500).json({ error: 'Failed to fetch recent bills' });
    }
});



app.post('/api/return-medicine', async (req, res) => {
    const { owner_id, invoice_id, item_id, medicine_name, return_quantity, mrp, refund_amount } = req.body;
    const client = await pool.connect();
    
    try {
        await client.query('BEGIN');

        const itemUpdate = await client.query(
            `UPDATE sale_items SET quantity = quantity - $1 WHERE item_id = $2 RETURNING quantity`,
            [return_quantity, item_id]
        );

        // 🔥 FIX: Loading aur crash issue ko rokne ke liye ye condition zaroori hai
        if (itemUpdate.rows.length > 0 && itemUpdate.rows[0].quantity <= 0) {
            await client.query(`DELETE FROM sale_items WHERE item_id = $1`, [item_id]);
        }

        const finalRefund = refund_amount ? parseFloat(refund_amount) : (return_quantity * mrp);
        
        await client.query(
            `UPDATE sales_invoices SET total_amount = total_amount - $1 WHERE invoice_id = $2`,
            [finalRefund, invoice_id]
        );

        const invUpdate = await client.query(
            `UPDATE shop_inventory SET quantity = quantity + $1 
             WHERE owner_id = $2 AND medicine_name = $3 AND mrp = $4 RETURNING *`,
            [return_quantity, owner_id, medicine_name, mrp]
        );

        if (invUpdate.rows.length === 0) {
            await client.query(
                `INSERT INTO shop_inventory (owner_id, medicine_name, quantity, mrp, batch_no) 
                 VALUES ($1, $2, $3, $4, 'RETURNED')`,
                [owner_id, medicine_name, return_quantity, mrp]
            );
        }

        await client.query('COMMIT');
        res.json({ 
            success: true, 
            message: `Returned ${return_quantity} ${medicine_name} successfully! Refund: ₹${finalRefund.toFixed(2)}` 
        });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error("Return Medicine Error:", err.message);
        res.status(500).json({ error: 'Failed to process return' });
    } finally {
        client.release();
    }
});

app.get('/api/detailed-report/:owner_id/:type', async (req, res) => {
    const { owner_id, type } = req.params;
    try {
        let query = '';
        if (type === 'month') {
            
            query = `SELECT to_char(sale_date, 'DD-Mon-YYYY') as label, SUM(total_amount) as total 
                     FROM sales_invoices 
                     WHERE owner_id = $1 AND date_trunc('month', sale_date) = date_trunc('month', CURRENT_DATE) 
                     GROUP BY label, DATE(sale_date) 
                     ORDER BY DATE(sale_date) DESC`;
                     
        } else if (type === 'year') {
            
            query = `SELECT to_char(sale_date, 'FMMonth') as label, SUM(total_amount) as total, EXTRACT(month FROM sale_date) as m_num 
                     FROM sales_invoices 
                     WHERE owner_id = $1 AND date_trunc('year', sale_date) = date_trunc('year', CURRENT_DATE) 
                     GROUP BY label, m_num 
                     ORDER BY m_num DESC`;
                     
        } else if (type === 'lifetime') {
            
            query = `SELECT EXTRACT(year FROM sale_date)::text as label, SUM(total_amount) as total 
                     FROM sales_invoices 
                     WHERE owner_id = $1 
                     GROUP BY label 
                     ORDER BY label DESC LIMIT 10`;
        } else {
            return res.status(400).json({ error: 'Invalid type' });
        }

        const result = await pool.query(query, [owner_id]);
        res.json({ success: true, data: result.rows });
    } catch (err) {
        console.error("Detailed Report Error:", err.message);
        res.status(500).json({ error: 'Failed to fetch detailed report' });
    }
});


app.put('/api/inventory/quick-edit/:id', async (req, res) => {
    const { id } = req.params;
    const { tablets_per_strip } = req.body;
    try {
        await pool.query(
            'UPDATE shop_inventory SET tablets_per_strip = $1 WHERE inventory_id = $2',
            [parseInt(tablets_per_strip) || 1, id]
        );
        res.json({ success: true, message: 'Pack size updated successfully!' });
    } catch (err) {
        console.error("Quick Edit Error:", err.message);
        res.status(500).json({ error: 'Failed to update pack size' });
    }
});

// 🔍 SEARCH BILLS BY CUSTOMER NAME OR MOBILE
app.get('/api/search-bills/:owner_id', async (req, res) => {
    const { owner_id } = req.params;
    const { query } = req.query;

    try {
        const searchTerm = `%${query}%`;
        
        // 🔥 Flutter UI ke hisaab se columns ko rename (AS) kiya gaya hai
        const searchResult = await pool.query(
            `SELECT 
                id AS invoice_id, 
                invoice_no, 
                customer_name, 
                customer_mobile, 
                total_amount, 
                cart_items AS items, 
                created_at AS sale_date 
             FROM sales 
             WHERE owner_id = $1 
             AND (customer_mobile ILIKE $2 OR customer_name ILIKE $2)
             ORDER BY created_at DESC 
             LIMIT 20`,
            [owner_id, searchTerm]
        );

        res.json({ success: true, data: searchResult.rows });
    } catch (err) {
        console.error("❌ Search Bill Error:", err.message);
        res.status(500).json({ error: 'Failed to search bills.' });
    }
});
console.log(`refund fix test`);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
