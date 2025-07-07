#!/bin/bash

# ตั้งค่าตัวแปรสำหรับเก็บผลรวมทั้งหมด
TOTAL_TEST_CASES=0

echo "Starting Robot Framework test case count across directories..."
echo "---------------------------------------------------------"

# ใช้ find เพื่อค้นหาทุกไดเรกทอรีที่มีไฟล์ .robot อยู่
# -type d: ค้นหาเฉพาะไดเรกทอรี
# -exec sh -c ...: รันคำสั่ง shell สำหรับแต่ละไดเรกทอรีที่พบ
#   find_dir: ตัวแปรชั่วคราวสำหรับชื่อไดเรกทอรีที่ find พบ
#   -maxdepth 1 -name "*.robot": ตรวจสอบว่ามีไฟล์ .robot ในไดเรกทอรีนั้นหรือไม่
#   ถ้ามี ให้ดำเนินการต่อ
find . -type d -print0 | while IFS= read -r -d $'\0' find_dir; do
    # ตรวจสอบว่าไดเรกทอรีนั้นมีไฟล์ .robot อยู่หรือไม่
    # เพื่อหลีกเลี่ยงการรัน robot ในโฟลเดอร์ที่ไม่มี test
    if find "$find_dir" -maxdepth 1 -name "*.robot" | grep -q .; then
        echo "Processing directory: $find_dir"

        # เปลี่ยนไปที่ไดเรกทอรีนั้นๆ
        pushd "$find_dir" > /dev/null

        # รันคำสั่ง robot --dryrun และเก็บผลลัพธ์
        # 2>&1: รวม stderr เข้ากับ stdout เพื่อให้ grep/awk เห็นข้อความ error ด้วย
        # || true: ป้องกันไม่ให้สคริปต์หยุดทำงานหากคำสั่ง robot คืนค่า error (เช่น ไม่มี test)
        ROBOT_OUTPUT=$(robot --dryrun --output NONE --log NONE --report NONE . 2>&1 || true)

        # ดึงตัวเลขจำนวน test cases total ออกมา
        # grep "tests total": กรองบรรทัดที่มีคำว่า "tests total"
        # awk '{print $1}': ดึงคำแรกของบรรทัดนั้น (ซึ่งคือตัวเลข)
        # tr -d '\r': ลบอักขระ carriage return ที่อาจติดมาในบางระบบ
        # head -n 1: หากมีหลายบรรทัดที่ตรงกัน ให้เอาแค่บรรทัดแรก
        NUM_TESTS=$(echo "$ROBOT_OUTPUT" | grep "tests total" | awk '{print $1}' | tr -d '\r' | tail -n 1)

        # ตรวจสอบว่าได้ตัวเลขมาหรือไม่
        if [[ "$NUM_TESTS" =~ ^[0-9]+$ ]]; then
            echo "  Found $NUM_TESTS tests in this directory."
            TOTAL_TEST_CASES=$((TOTAL_TEST_CASES + NUM_TESTS))
            echo "Total : $TOTAL_TEST_CASES"
        else
          NUM_TESTS=$(echo "$ROBOT_OUTPUT" | grep "test total" | awk '{print $1}' | tr -d '\r' | tail -n 1)
          if [[ "$NUM_TESTS" =~ ^[0-9]+$ ]]; then
            echo "  Found $NUM_TESTS tests in this directory."
            TOTAL_TEST_CASES=$((TOTAL_TEST_CASES + NUM_TESTS))
            echo "Total : $TOTAL_TEST_CASES"
          else
            echo "  No 'tests total' count found or invalid format in this directory."
          fi
            # Optional: uncomment the line below to see the full output if extraction fails
            # echo "--- Full Robot Output ---"
            # echo "$ROBOT_OUTPUT"
            # echo "-------------------------"
        fi

        # กลับไปยังไดเรกทอรีเดิม
        popd > /dev/null
        echo "---------------------------------------------------------"
    fi
    echo ""
  echo "========================================================="
  echo "Total Test Cases across all directories: $TOTAL_TEST_CASES"
  echo "========================================================="
done
