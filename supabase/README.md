# ย้ายระบบรายรับรายจ่ายมาใช้ Supabase

## ตั้งค่าโปรเจกต์

1. สร้างโปรเจกต์ Supabase แล้วเก็บรหัสผ่านฐานข้อมูลไว้ในที่ปลอดภัย
2. ไปที่ **SQL Editor** แล้วรัน migration ตามลำดับ: `001_initial_schema.sql`, `002_lock_previous_month_transactions.sql` และ `003_recurring_expense_templates.sql`
3. ไปที่ **Authentication → Users** แล้วสร้างผู้ใช้ด้วยอีเมลและรหัสผ่านของเจ้าของระบบ
4. สำหรับระบบใช้ส่วนตัว ให้ปิดการสมัครสมาชิกสาธารณะที่ **Authentication → Providers → Email** เพื่อไม่ให้บุคคลทั่วไปสร้างบัญชีเอง
5. ไปที่ **Project Settings → API** แล้วคัดลอก Project URL และ **Publishable key** (หรือ legacy `anon` key)
6. ใส่สองค่านั้นใน `public/supabase-config.js` แล้วอัปโหลดไฟล์ทั้งชุดไปยัง Cloudflare

## คีย์และความปลอดภัย

`public/supabase-config.js` ถูกส่งไปยังเบราว์เซอร์ จึงใส่ได้เฉพาะ Project URL กับ Publishable key เท่านั้น ห้ามใส่ `service_role` หรือ secret key ในแอป

ตารางทั้งสองเปิด Row Level Security และนโยบายกำหนดให้ผู้ใช้เห็นและแก้ไขได้เฉพาะแถวที่ `user_id` ตรงกับบัญชีที่ล็อกอิน หากใช้ข้อมูลจริง ให้ตรวจสอบว่า SQL migration รันสำเร็จและมี RLS ก่อนเปิดแอป

## ย้ายข้อมูลเดิมจาก Google Sheets

โค้ดหน้าเว็บเลิกเรียก Apps Script แล้ว แต่ข้อมูลเดิมไม่ได้ถูกคัดลอกให้อัตโนมัติ ต้อง export แผ่นธุรกรรมและหมวดหมู่จาก Google Sheets เป็น CSV แล้วนำเข้าตารางที่ตรงกันใน Supabase Table Editor หรือแปลง CSV ตามคอลัมน์นี้:

- `finance_transactions`: `user_id`, `type`, `transaction_date` (`YYYY-MM-DD`), `amount`, `category`, `detail`, `note`
- `finance_categories`: `user_id`, `type`, `name`, `memos` (JSON array), `icon`, `color`

นำ User ID จาก **Authentication → Users** มาใส่ใน `user_id` ของแต่ละแถวก่อนนำเข้า อย่านำเข้าแถวของผู้ใช้อื่นด้วยบัญชีเจ้าของระบบ

## เปิดแอปครั้งแรก

หลังตั้งค่า SQL, ผู้ใช้ Auth และไฟล์ config แล้ว ให้เปิดเว็บและเข้าสู่ระบบด้วยอีเมล/รหัสผ่านที่สร้างไว้ใน Supabase Dashboard ไม่มีปุ่มสมัครสมาชิกในหน้าแอป
