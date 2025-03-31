import 'package:flutter/material.dart';

Widget buildSettingItem({
  required String title,
  required VoidCallback onTap,
  Color? iconColor,
  Color? backgroundColor,
  bool showDivider = true,
  bool? toggleValue,
  Function(bool)? onToggleChanged,
}) {
  // check show toggle 
  final bool isToggleItem = title == "Theme" || toggleValue != null;

  return Column(
    children: [
      InkWell(
        onTap:
            isToggleItem
                ? null
                : onTap, // ปิดการใช้งาน onTap ถ้าเป็น toggle item

        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          child: Row(
            children: [
              const SizedBox(width: 16),

              Expanded(
                
                child: Padding(
                  padding: EdgeInsets.fromLTRB(25, 0, 0, 0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // ส่วนด้านขวา (toggle หรือ chevron)
              if (isToggleItem)
                // show toggle switch
                Switch(
                  value: toggleValue ?? false,
                  onChanged: onToggleChanged,
                  activeColor: const Color.fromARGB(255, 0, 0, 0),
                )
              else
                // show arrow
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: Colors.grey.shade600,
                ),
            ],
          ),
        ),
      ),

      // เส้นคั่นด้านล่าง
      if (showDivider)
        Divider(
          height: 1,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
          color: Colors.grey.shade300,
        ),
    ],
  );
}
