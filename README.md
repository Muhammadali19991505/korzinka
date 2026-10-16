# 🛒 Korzinka E-Commerce & Retail — SQL Data Analysis

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-SQL%20Analytics-336791?logo=postgresql&logoColor=white)
![Data Analysis](https://img.shields.io/badge/Data%20Analysis-Business%20Intelligence-blue)
![RFM Analysis](https://img.shields.io/badge/Customer%20Retention-RFM%20Metrics-green)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

Ushbu repozitoriy chakana savdo (Retail / E-commerce) ma'lumotlar bazasi ustida **SQL (PostgreSQL)** yordamida bajarilgan kompleks biznes va moliyaviy tahlillarni (`korzinka_db.sql`) o'z ichiga oladi. Loyiha mahsulot toifalari rentabelligi, oylik savdo dinamikasi, O'zbekiston shaharlari kesimidagi xarid xulq-atvori hamda mijozlarni saqlab qolish (**Retention / RFM**) ko'rsatkichlarini hisoblashga qaratilgan.

---

## 🗄 Ma'lumotlar Bazasi Sxemasi (Database Schema)

SQL so'rovlari o'zaro bog'langan 4 ta asosiy jadval ustida ishlaydi:

| Jadval nomi | Asosiy ustunlar | Tavsifi |
| :--- | :--- | :--- |
| **`customers`** | `customer_id`, `first_name`, `last_name`, `city` | Mijozlarning shaxsiy ma'lumotlari va yashash shahri |
| **`orders`** | `order_id`, `customer_id`, `order_date`, `order_status`, `payment_method` | Buyurtmalar tarixi, holati (`'Yetkazildi'`) va to'lov usuli |
| **`order_items`** | `order_id`, `product_id`, `quantity`, `discount_percent` | Buyurtma ichidagi mahsulotlar miqdori va chegirma foizi |
| **`products`** | `product_id`, `category`, `selling_price`, `cost_price` | Mahsulot toifasi, sotuv narxi va tannarxi |

> **💡 Muhim eslatma:** Barcha moliyaviy va mijozlar tahlilida faqatgina muvaffaqiyatli yakunlangan (`order_status = 'Yetkazildi'`) buyurtmalar hisobga olingan.

---

## 📊 Tahlil Yo'nalishlari va Biznes Metrikalar

Loyiha 2 ta asosiy bo'lim va 4 ta tahliliy blokdan iborat:

### 1-BO'LIM: Savdo, Rentabellik va Geografik Tahlil

#### 🔹 Topshiriq 1.1: Mahsulot toifalari bo'yicha rentabellik tahlili
Har bir mahsulot toifasi (`category`) bo'yicha quyidagi moliyaviy ko'rsatkichlar hisoblangan:
* **Sotilgan jami mahsulotlar (`total_quantity`):** `SUM(oi.quantity)`
* **Sof daromad (`net_revenue`):** Chegirmalar chegirib tashlangandagi tushum:
  $$\text{Net Revenue} = \sum \left(\text{quantity} \times \text{selling\_price} \times \left(1 - \frac{\text{discount\_percent}}{100}\right)\right)$$
* **Yalpi foyda (`gross_profit`):** Sof daromaddan mahsulot tannarxi (`quantity * cost_price`) ayirmasi.
* **Foyda marjasi (`profit_margin_percent`):** `CTE (WITH savdo_jadvali)` orqali yalpi foydaning sof daromaddagi foiz ulushi.

#### 🔹 Topshiriq 1.2: 2026-yil oylik savdo dinamikasi (Time-Series Analysis)
2026-yilning har bir oyi (`EXTRACT(MONTH FROM order_date)`) kesimida:
* Jami yetkazilgan buyurtmalar soni (`orders_count`)
* Xarid qilgan unikal mijozlar soni (`unique_customers`)
* Oylik sof daromad (`net_revenue`)
* O'rtacha xarid cheki — **AOV** (`net_revenue / orders_count`)

#### 🔹 Topshiriq 1.3: O'zbekiston shaharlari kesimida AOV va To'lov usullari
* **Shaharlar bo'yicha AOV:** Har bir buyurtma summasi jamlanib (`WITH har_bir_chek`), shaharlar (`city`) kesimida jami buyurtmalar, jami tushum va o'rtacha chek (`AVG(chek_summasi)`) hisoblangan.
* **Eng ommabop to'lov usuli:** `ROW_NUMBER() OVER (PARTITION BY c.city ORDER BY COUNT(o.order_id) DESC)` oynali funksiyasi (Window Function) yordamida har bir shaharda 1-o'rindagi (`orin = 1`) to'lov usuli (`payment_method`) aniqlangan.

---

### 2-BO'LIM: Mijozlar Harakati va Saqlab Qolish (Retention & RFM)

Mijozlarning sodiqligi va faolligini baholash uchun **RFM (Recency, Frequency, Monetary)** ko'rsatkichlari shakllantirilgan:

1. **Frequency & Lifespan (Faollik):** Har bir mijozning birinchi xarid sanasi (`MIN(order_date)`), oxirgi xarid sanasi (`MAX(order_date)`) va jami xaridlar soni (`COUNT(order_id)`).
2. **Monetary (Daromadlilik):** Mijozning chegirmalar hisobga olingan holda kompaniyaga keltirgan jami sof tushumi (`jami_sarflangan_summa`).
3. **Recency (Oxirgi faollik muddati):** Mijozning oxirgi xarididan bugungi kungacha o'tgan kunlar soni (`CURRENT_DATE - MAX(o.order_date)`).

---

## 🛠 Foydalanilgan SQL Texnikalar

* **Murakkab birlashtirishlar (Multi-table JOINs):** `INNER JOIN` orqali 3–4 ta jadvalni optimal bog'lash.
* **Common Table Expressions (CTE):** `WITH ... AS` bloklari orqali ko'p bosqichli hisob-kitoblarni (masalan, oldin chek summasini, keyin shahar o'rtachasini topish) soddalashtirish.
* **Window Functions (Oynali funksiyalar):** `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` yordamida guruhlar ichida reytinglash.
* **Sana va Vaqt funksiyalari:** `EXTRACT(YEAR/MONTH FROM ...)`, `MIN()`, `MAX()`, `CURRENT_DATE`.
* **Agregatsiya va Matematik amallar:** `SUM()`, `COUNT(DISTINCT ...)`, `AVG()`, `ROUND()`.

---

## 🚀 Ishga Tushirish Bo'yicha Qo'llanma

1. Repozitoriyani klonlang:
   ```bash
   git clone [https://github.com/Muhammadali19991505/repo-name.git](https://github.com/Muhammadali19991505/repo-name.git)
   cd repo-name
