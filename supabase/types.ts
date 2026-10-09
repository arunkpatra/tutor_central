
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "graphql_public": {
          Tables: {
            [_ in never]: never
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "graphql":
{ Args: { "extensions"?: Json,"operationName"?: string,"query"?: string,"variables"?: Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        },"public": {
          Tables: {
            "ai_generations": {
                  Row: {
                    "centre_id": string,"created_at": string,"id": string,"input": NonNullable<Json>,"kind": Database["public"]['Enums']["ai_kind"],"model": string | null,"output": string | null,"status": Database["public"]['Enums']["ai_status"],"tokens_in": number | null,"tokens_out": number | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"created_at"?: string,"id"?: string,"input": NonNullable<Json>,"kind": Database["public"]['Enums']["ai_kind"],"model"?: string | null,"output"?: string | null,"status"?: Database["public"]['Enums']["ai_status"],"tokens_in"?: number | null,"tokens_out"?: number | null,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"created_at"?: string,"id"?: string,"input"?: NonNullable<Json>,"kind"?: Database["public"]['Enums']["ai_kind"],"model"?: string | null,"output"?: string | null,"status"?: Database["public"]['Enums']["ai_status"],"tokens_in"?: number | null,"tokens_out"?: number | null,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "ai_generations_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"attendance_marks": {
                  Row: {
                    "centre_id": string,"created_at": string,"id": string,"session_id": string,"status": Database["public"]['Enums']["attendance_status"],"student_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"created_at"?: string,"id"?: string,"session_id": string,"status": Database["public"]['Enums']["attendance_status"],"student_id": string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"created_at"?: string,"id"?: string,"session_id"?: string,"status"?: Database["public"]['Enums']["attendance_status"],"student_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "attendance_marks_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "attendance_marks_centre_id_session_id_fkey"
      columns: ["centre_id","session_id"]
isOneToOne: false
      referencedRelation: "attendance_sessions"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "attendance_marks_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"attendance_sessions": {
                  Row: {
                    "centre_id": string,"class_id": string | null,"created_at": string,"date": string,"id": string,"saved_at": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"class_id"?: string | null,"created_at"?: string,"date": string,"id"?: string,"saved_at"?: string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"class_id"?: string | null,"created_at"?: string,"date"?: string,"id"?: string,"saved_at"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "attendance_sessions_centre_id_class_id_fkey"
      columns: ["centre_id","class_id"]
isOneToOne: false
      referencedRelation: "classes"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "attendance_sessions_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"calendar_events": {
                  Row: {
                    "centre_id": string,"created_at": string,"date": string,"end_time": string | null,"id": string,"note": string | null,"start_time": string | null,"title": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"created_at"?: string,"date": string,"end_time"?: string | null,"id"?: string,"note"?: string | null,"start_time"?: string | null,"title": string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"created_at"?: string,"date"?: string,"end_time"?: string | null,"id"?: string,"note"?: string | null,"start_time"?: string | null,"title"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "calendar_events_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"centre_members": {
                  Row: {
                    "centre_id": string,"created_at": string,"role": Database["public"]['Enums']["centre_role"],"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"created_at"?: string,"role"?: Database["public"]['Enums']["centre_role"],"user_id": string
                  }
                  Update: {
                    "centre_id"?: string,"created_at"?: string,"role"?: Database["public"]['Enums']["centre_role"],"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "centre_members_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"centres": {
                  Row: {
                    "ai_consent_at": string | null,"created_at": string,"currency": string,"id": string,"name": string,"owner_id": string,"payment_link": string | null,"send_receipts": boolean,"updated_at": string,"upi_confirmed_at": string | null,"upi_id": string | null,"whatsapp_number": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "ai_consent_at"?: string | null,"created_at"?: string,"currency"?: string,"id"?: string,"name": string,"owner_id": string,"payment_link"?: string | null,"send_receipts"?: boolean,"updated_at"?: string,"upi_confirmed_at"?: string | null,"upi_id"?: string | null,"whatsapp_number"?: string | null
                  }
                  Update: {
                    "ai_consent_at"?: string | null,"created_at"?: string,"currency"?: string,"id"?: string,"name"?: string,"owner_id"?: string,"payment_link"?: string | null,"send_receipts"?: boolean,"updated_at"?: string,"upi_confirmed_at"?: string | null,"upi_id"?: string | null,"whatsapp_number"?: string | null
                  }
                  Relationships: [
                    
                  ]
                },"classes": {
                  Row: {
                    "archived_at": string | null,"centre_id": string,"created_at": string,"end_time": string | null,"id": string,"meeting_days": (number)[],"monthly_fee": number | null,"name": string,"start_time": string | null,"subject": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"centre_id": string,"created_at"?: string,"end_time"?: string | null,"id"?: string,"meeting_days"?: (number)[],"monthly_fee"?: number | null,"name": string,"start_time"?: string | null,"subject"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "archived_at"?: string | null,"centre_id"?: string,"created_at"?: string,"end_time"?: string | null,"id"?: string,"meeting_days"?: (number)[],"monthly_fee"?: number | null,"name"?: string,"start_time"?: string | null,"subject"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "classes_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"fee_invoices": {
                  Row: {
                    "amount": number,"centre_id": string,"created_at": string,"id": string,"paid_at": string | null,"paid_method": Database["public"]['Enums']["paid_method"] | null,"period": string,"status": Database["public"]['Enums']["fee_status"],"student_id": string,"updated_at": string,"waived_reason": string | null
                  }
                  ComputedFields: never
                  Insert: {
                    "amount": number,"centre_id": string,"created_at"?: string,"id"?: string,"paid_at"?: string | null,"paid_method"?: Database["public"]['Enums']["paid_method"] | null,"period": string,"status"?: Database["public"]['Enums']["fee_status"],"student_id": string,"updated_at"?: string,"waived_reason"?: string | null
                  }
                  Update: {
                    "amount"?: number,"centre_id"?: string,"created_at"?: string,"id"?: string,"paid_at"?: string | null,"paid_method"?: Database["public"]['Enums']["paid_method"] | null,"period"?: string,"status"?: Database["public"]['Enums']["fee_status"],"student_id"?: string,"updated_at"?: string,"waived_reason"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "fee_invoices_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "fee_invoices_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"message_log": {
                  Row: {
                    "about_date": string | null,"centre_id": string,"channel": Database["public"]['Enums']["message_channel"],"created_at": string,"id": string,"kind": Database["public"]['Enums']["message_kind"],"opened_at": string,"student_id": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "about_date"?: string | null,"centre_id": string,"channel"?: Database["public"]['Enums']["message_channel"],"created_at"?: string,"id"?: string,"kind": Database["public"]['Enums']["message_kind"],"opened_at"?: string,"student_id"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "about_date"?: string | null,"centre_id"?: string,"channel"?: Database["public"]['Enums']["message_channel"],"created_at"?: string,"id"?: string,"kind"?: Database["public"]['Enums']["message_kind"],"opened_at"?: string,"student_id"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "message_log_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "message_log_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"profiles": {
                  Row: {
                    "created_at": string,"display_name": string | null,"has_password": boolean,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"display_name"?: string | null,"has_password"?: boolean,"updated_at"?: string,"user_id": string
                  }
                  Update: {
                    "created_at"?: string,"display_name"?: string | null,"has_password"?: boolean,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    
                  ]
                },"students": {
                  Row: {
                    "archived_at": string | null,"centre_id": string,"class_id": string | null,"created_at": string,"date_of_birth": string | null,"gender": string | null,"id": string,"monthly_fee": number | null,"name": string,"notes": string | null,"parent_name": string | null,"parent_phone": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"centre_id": string,"class_id"?: string | null,"created_at"?: string,"date_of_birth"?: string | null,"gender"?: string | null,"id"?: string,"monthly_fee"?: number | null,"name": string,"notes"?: string | null,"parent_name"?: string | null,"parent_phone"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "archived_at"?: string | null,"centre_id"?: string,"class_id"?: string | null,"created_at"?: string,"date_of_birth"?: string | null,"gender"?: string | null,"id"?: string,"monthly_fee"?: number | null,"name"?: string,"notes"?: string | null,"parent_name"?: string | null,"parent_phone"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "students_centre_id_class_id_fkey"
      columns: ["centre_id","class_id"]
isOneToOne: false
      referencedRelation: "classes"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "students_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"tasks": {
                  Row: {
                    "centre_id": string,"created_at": string,"done_at": string | null,"due_date": string | null,"id": string,"title": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"created_at"?: string,"done_at"?: string | null,"due_date"?: string | null,"id"?: string,"title": string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"created_at"?: string,"done_at"?: string | null,"due_date"?: string | null,"id"?: string,"title"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "tasks_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "archive_class":
{ Args: { "p_class": string }; Returns: undefined
                           },
"create_centre":
{ Args: { "p_display_name"?: string,"p_name": string,"p_whatsapp"?: string }; Returns: string
                           },
"delete_account":
{ Args: Record<PropertyKey, never>; Returns: undefined
                           },
"delete_centre":
{ Args: { "p_centre": string }; Returns: undefined
                           },
"generate_fees":
{ Args: { "p_centre": string,"p_period": string }; Returns: number
                           },
"is_member":
{ Args: { "c": string }; Returns: boolean
                           },
"save_attendance":
{ Args: { "p_centre": string,"p_class": string,"p_date": string,"p_marks": Json }; Returns: string
                           },
"start_ai_generation":
{ Args: { "p_centre": string,"p_input": Json,"p_kind": Database["public"]['Enums']["ai_kind"],"p_model": string }; Returns: string
                           }
          }
          Enums: {
            "ai_kind": "paper"|"homework"|"worksheet"|"progress_note"|"scan_register"|"check_paper","ai_status": "ok"|"failed"|"pending","attendance_status": "present"|"absent","centre_role": "owner"|"teacher","fee_status": "due"|"paid"|"waived","message_channel": "whatsapp_link","message_kind": "reminder"|"receipt"|"absence"|"progress","paid_method": "upi"|"cash"|"other"
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "graphql_public": {
          Enums: {
            
          }
        },"public": {
          Enums: {
            "ai_kind": ["paper", "homework", "worksheet", "progress_note", "scan_register", "check_paper"],"ai_status": ["ok", "failed", "pending"],"attendance_status": ["present", "absent"],"centre_role": ["owner", "teacher"],"fee_status": ["due", "paid", "waived"],"message_channel": ["whatsapp_link"],"message_kind": ["reminder", "receipt", "absence", "progress"],"paid_method": ["upi", "cash", "other"]
          }
        }
} as const
