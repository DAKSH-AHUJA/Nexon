-- Nexon ERP Supabase Database Schema
-- Run this in your Supabase SQL Editor to create the required tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Companies table (for multi-tenant support)
CREATE TABLE IF NOT EXISTS companies (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    account_code TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    business_type TEXT DEFAULT 'Wholesale Trading',
    gst TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    company_id UUID REFERENCES companies(id),
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT DEFAULT '',
    gst TEXT DEFAULT '',
    address TEXT DEFAULT '',
    city TEXT DEFAULT '',
    outstanding_balance DECIMAL(12,2) DEFAULT 0,
    total_purchases DECIMAL(12,2) DEFAULT 0,
    status TEXT DEFAULT 'active',
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    company_id UUID REFERENCES companies(id),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit TEXT DEFAULT 'kg',
    current_stock DECIMAL(12,2) DEFAULT 0,
    purchase_price DECIMAL(12,2) DEFAULT 0,
    selling_price DECIMAL(12,2) DEFAULT 0,
    minimum_stock DECIMAL(12,2) DEFAULT 0,
    description TEXT DEFAULT '',
    is_deleted BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    company_id UUID REFERENCES companies(id),
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT DEFAULT '',
    gst TEXT DEFAULT '',
    address TEXT DEFAULT '',
    city TEXT DEFAULT '',
    outstanding_payment DECIMAL(12,2) DEFAULT 0,
    total_purchases DECIMAL(12,2) DEFAULT 0,
    status TEXT DEFAULT 'active',
    is_deleted BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoices table
CREATE TABLE IF NOT EXISTS invoices (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    company_id UUID REFERENCES companies(id),
    invoice_no TEXT NOT NULL,
    customer_id UUID REFERENCES customers(id),
    customer_name TEXT NOT NULL,
    subtotal DECIMAL(12,2) DEFAULT 0,
    total_gst DECIMAL(12,2) DEFAULT 0,
    grand_total DECIMAL(12,2) DEFAULT 0,
    status TEXT DEFAULT 'pending',
    is_deleted BOOLEAN DEFAULT FALSE,
    date TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoice Items table
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_name TEXT NOT NULL,
    quantity DECIMAL(12,2) NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    discount DECIMAL(5,2) DEFAULT 0,
    gst_rate DECIMAL(5,2) DEFAULT 5
);

-- Inventory Transactions table
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    company_id UUID REFERENCES companies(id),
    product_id UUID REFERENCES products(id),
    product_name TEXT NOT NULL,
    type TEXT NOT NULL,
    quantity DECIMAL(12,2) NOT NULL,
    date TIMESTAMPTZ DEFAULT NOW(),
    note TEXT DEFAULT '',
    user_name TEXT DEFAULT 'Admin'
);

-- Ledger Entries table
CREATE TABLE IF NOT EXISTS ledger_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID REFERENCES customers(id),
    description TEXT NOT NULL,
    debit DECIMAL(12,2) DEFAULT 0,
    credit DECIMAL(12,2) DEFAULT 0,
    balance DECIMAL(12,2) NOT NULL,
    date TIMESTAMPTZ DEFAULT NOW()
);

-- Caret Entries table
CREATE TABLE IF NOT EXISTS caret_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    company_id UUID REFERENCES companies(id),
    party_id TEXT NOT NULL,
    party_name TEXT NOT NULL,
    type TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    reference_number TEXT,
    date TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_company ON customers(company_id);
CREATE INDEX IF NOT EXISTS idx_products_company ON products(company_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_company ON suppliers(company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_company ON invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product ON inventory_transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_ledger_customer ON ledger_entries(customer_id);

-- Enable Row Level Security
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE caret_entries ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
CREATE POLICY "Allow authenticated access" ON companies FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON customers FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON products FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON suppliers FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON invoices FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON invoice_items FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON inventory_transactions FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON ledger_entries FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated access" ON caret_entries FOR ALL USING (auth.role() = 'authenticated');

-- Enable Real-time subscriptions
ALTER PUBLICATION supabase_realtime ADD TABLE customers;
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE suppliers;
ALTER PUBLICATION supabase_realtime ADD TABLE invoices;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory_transactions;

-- Insert default company
INSERT INTO companies (name, account_code, password, business_type, gst)
VALUES ('Rajesh Trading Company', 'rajesh', '12345', 'Wholesale Vegetable Trading', 'GSTIN not configured')
ON CONFLICT (account_code) DO NOTHING;