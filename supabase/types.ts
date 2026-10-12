
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
                    "centre_id": string,"created_at": string,"id": string,"input": NonNullable<Json>,"kind": Database["public"]['Enums']["ai_kind"],"model": string | null,"output": string | null,"status": Database["public"]['Enums']["ai_status"],"student_id": string | null,"tokens_in": number | null,"tokens_out": number | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"created_at"?: string,"id"?: string,"input": NonNullable<Json>,"kind": Database["public"]['Enums']["ai_kind"],"model"?: string | null,"output"?: string | null,"status"?: Database["public"]['Enums']["ai_status"],"student_id"?: string | null,"tokens_in"?: number | null,"tokens_out"?: number | null,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"created_at"?: string,"id"?: string,"input"?: NonNullable<Json>,"kind"?: Database["public"]['Enums']["ai_kind"],"model"?: string | null,"output"?: string | null,"status"?: Database["public"]['Enums']["ai_status"],"student_id"?: string | null,"tokens_in"?: number | null,"tokens_out"?: number | null,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "ai_generations_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "ai_generations_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"artefacts": {
                  Row: {
                    "centre_id": string,"content": NonNullable<Json>,"created_at": string,"generation_id": string | null,"id": string,"kind": Database["public"]['Enums']["artefact_kind"],"made_from": string | null,"photo_path": string | null,"plan_id": string | null,"regenerated_from": string | null,"school_item_id": string | null,"source": Database["public"]['Enums']["artefact_source"],"student_id": string | null,"title": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"content"?: NonNullable<Json>,"created_at"?: string,"generation_id"?: string | null,"id"?: string,"kind": Database["public"]['Enums']["artefact_kind"],"made_from"?: string | null,"photo_path"?: string | null,"plan_id"?: string | null,"regenerated_from"?: string | null,"school_item_id"?: string | null,"source"?: Database["public"]['Enums']["artefact_source"],"student_id"?: string | null,"title": string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"content"?: NonNullable<Json>,"created_at"?: string,"generation_id"?: string | null,"id"?: string,"kind"?: Database["public"]['Enums']["artefact_kind"],"made_from"?: string | null,"photo_path"?: string | null,"plan_id"?: string | null,"regenerated_from"?: string | null,"school_item_id"?: string | null,"source"?: Database["public"]['Enums']["artefact_source"],"student_id"?: string | null,"title"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "artefacts_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "artefacts_centre_id_generation_id_fkey"
      columns: ["centre_id","generation_id"]
isOneToOne: false
      referencedRelation: "ai_generations"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "artefacts_centre_id_plan_id_fkey"
      columns: ["centre_id","plan_id"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "artefacts_centre_id_regenerated_from_fkey"
      columns: ["centre_id","regenerated_from"]
isOneToOne: false
      referencedRelation: "artefacts"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "artefacts_centre_id_school_item_id_fkey"
      columns: ["centre_id","school_item_id"]
isOneToOne: false
      referencedRelation: "school_items"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "artefacts_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
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
                    "centre_id": string,"class_id": string | null,"closed_at": string | null,"created_at": string,"date": string,"id": string,"plan_id": string | null,"saved_at": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"class_id"?: string | null,"closed_at"?: string | null,"created_at"?: string,"date": string,"id"?: string,"plan_id"?: string | null,"saved_at"?: string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"class_id"?: string | null,"closed_at"?: string | null,"created_at"?: string,"date"?: string,"id"?: string,"plan_id"?: string | null,"saved_at"?: string,"updated_at"?: string
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
    },{
      foreignKeyName: "attendance_sessions_centre_id_plan_id_fkey"
      columns: ["centre_id","plan_id"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["centre_id","id"]
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
                },"chapters": {
                  Row: {
                    "centre_id": string,"created_at": string,"id": string,"ladder": string | null,"name": string,"position": number,"student_id": string,"subject": string,"syllabus_id": string | null,"textbook_id": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"created_at"?: string,"id"?: string,"ladder"?: string | null,"name": string,"position": number,"student_id": string,"subject": string,"syllabus_id"?: string | null,"textbook_id"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"created_at"?: string,"id"?: string,"ladder"?: string | null,"name"?: string,"position"?: number,"student_id"?: string,"subject"?: string,"syllabus_id"?: string | null,"textbook_id"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "chapters_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "chapters_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "chapters_centre_id_textbook_id_fkey"
      columns: ["centre_id","textbook_id"]
isOneToOne: false
      referencedRelation: "textbooks"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "chapters_syllabus_id_fkey"
      columns: ["syllabus_id"]
isOneToOne: false
      referencedRelation: "syllabi"
      referencedColumns: ["id"]
    }
                  ]
                },"checks": {
                  Row: {
                    "centre_id": string,"correct": boolean,"created_at": string,"id": string,"kind": string,"question": NonNullable<Json>,"session_id": string | null,"skill_id": string,"student_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"correct": boolean,"created_at"?: string,"id"?: string,"kind"?: string,"question"?: NonNullable<Json>,"session_id"?: string | null,"skill_id": string,"student_id": string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"correct"?: boolean,"created_at"?: string,"id"?: string,"kind"?: string,"question"?: NonNullable<Json>,"session_id"?: string | null,"skill_id"?: string,"student_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "checks_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "checks_centre_id_session_id_fkey"
      columns: ["centre_id","session_id"]
isOneToOne: false
      referencedRelation: "attendance_sessions"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "checks_centre_id_skill_id_fkey"
      columns: ["centre_id","skill_id"]
isOneToOne: false
      referencedRelation: "skills"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "checks_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"classes": {
                  Row: {
                    "archived_at": string | null,"centre_id": string,"created_at": string,"end_time": string | null,"id": string,"meeting_days": (number)[],"monthly_fee": number | null,"name": string,"note_time": string | null,"note_weekday": number | null,"plan_groups": number | null,"plan_pattern": NonNullable<Json>,"start_time": string | null,"subject": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"centre_id": string,"created_at"?: string,"end_time"?: string | null,"id"?: string,"meeting_days"?: (number)[],"monthly_fee"?: number | null,"name": string,"note_time"?: string | null,"note_weekday"?: number | null,"plan_groups"?: number | null,"plan_pattern"?: NonNullable<Json>,"start_time"?: string | null,"subject"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "archived_at"?: string | null,"centre_id"?: string,"created_at"?: string,"end_time"?: string | null,"id"?: string,"meeting_days"?: (number)[],"monthly_fee"?: number | null,"name"?: string,"note_time"?: string | null,"note_weekday"?: number | null,"plan_groups"?: number | null,"plan_pattern"?: NonNullable<Json>,"start_time"?: string | null,"subject"?: string | null,"updated_at"?: string
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
                },"homework": {
                  Row: {
                    "artefact_id": string | null,"centre_id": string,"created_at": string,"given_at": string,"id": string,"session_id": string,"status": Database["public"]['Enums']["homework_status"],"student_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "artefact_id"?: string | null,"centre_id": string,"created_at"?: string,"given_at"?: string,"id"?: string,"session_id": string,"status"?: Database["public"]['Enums']["homework_status"],"student_id": string,"updated_at"?: string
                  }
                  Update: {
                    "artefact_id"?: string | null,"centre_id"?: string,"created_at"?: string,"given_at"?: string,"id"?: string,"session_id"?: string,"status"?: Database["public"]['Enums']["homework_status"],"student_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "homework_centre_id_artefact_id_fkey"
      columns: ["centre_id","artefact_id"]
isOneToOne: false
      referencedRelation: "artefacts"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "homework_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "homework_centre_id_session_id_fkey"
      columns: ["centre_id","session_id"]
isOneToOne: false
      referencedRelation: "attendance_sessions"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "homework_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"job_steps": {
                  Row: {
                    "attempt": number,"centre_id": string | null,"cost_paise": number,"created_at": string,"error": Json | null,"generation_id": string | null,"id": string,"job_id": string,"state": Database["public"]['Enums']["job_state"],"step": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "attempt": number,"centre_id"?: string | null,"cost_paise"?: number,"created_at"?: string,"error"?: Json | null,"generation_id"?: string | null,"id"?: string,"job_id": string,"state": Database["public"]['Enums']["job_state"],"step": string,"updated_at"?: string
                  }
                  Update: {
                    "attempt"?: number,"centre_id"?: string | null,"cost_paise"?: number,"created_at"?: string,"error"?: Json | null,"generation_id"?: string | null,"id"?: string,"job_id"?: string,"state"?: Database["public"]['Enums']["job_state"],"step"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "job_steps_centre_id_generation_id_fkey"
      columns: ["centre_id","generation_id"]
isOneToOne: false
      referencedRelation: "ai_generations"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "job_steps_centre_id_job_id_fkey"
      columns: ["centre_id","job_id"]
isOneToOne: false
      referencedRelation: "jobs"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "job_steps_job_id_fkey"
      columns: ["job_id"]
isOneToOne: false
      referencedRelation: "jobs"
      referencedColumns: ["id"]
    }
                  ]
                },"jobs": {
                  Row: {
                    "attempts": number,"centre_id": string | null,"cost_paise": number,"created_at": string,"created_by": string | null,"error": Json | null,"finished_at": string | null,"id": string,"idempotency_key": string,"input": NonNullable<Json>,"kind": Database["public"]['Enums']["job_kind"],"lease_until": string | null,"leased_by": string | null,"max_attempts": number,"result": Json | null,"run_at": string,"started_at": string | null,"state": Database["public"]['Enums']["job_state"],"step": NonNullable<Json>,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "attempts"?: number,"centre_id"?: string | null,"cost_paise"?: number,"created_at"?: string,"created_by"?: string | null,"error"?: Json | null,"finished_at"?: string | null,"id"?: string,"idempotency_key": string,"input"?: NonNullable<Json>,"kind": Database["public"]['Enums']["job_kind"],"lease_until"?: string | null,"leased_by"?: string | null,"max_attempts"?: number,"result"?: Json | null,"run_at"?: string,"started_at"?: string | null,"state"?: Database["public"]['Enums']["job_state"],"step"?: NonNullable<Json>,"updated_at"?: string
                  }
                  Update: {
                    "attempts"?: number,"centre_id"?: string | null,"cost_paise"?: number,"created_at"?: string,"created_by"?: string | null,"error"?: Json | null,"finished_at"?: string | null,"id"?: string,"idempotency_key"?: string,"input"?: NonNullable<Json>,"kind"?: Database["public"]['Enums']["job_kind"],"lease_until"?: string | null,"leased_by"?: string | null,"max_attempts"?: number,"result"?: Json | null,"run_at"?: string,"started_at"?: string | null,"state"?: Database["public"]['Enums']["job_state"],"step"?: NonNullable<Json>,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "jobs_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"marks": {
                  Row: {
                    "artefact_id": string | null,"centre_id": string,"created_at": string,"date": string,"id": string,"max": number,"photo_path": string | null,"questions": Json | null,"school_item_id": string | null,"score": number,"student_id": string,"subject": string,"test": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "artefact_id"?: string | null,"centre_id": string,"created_at"?: string,"date": string,"id"?: string,"max": number,"photo_path"?: string | null,"questions"?: Json | null,"school_item_id"?: string | null,"score": number,"student_id": string,"subject": string,"test": string,"updated_at"?: string
                  }
                  Update: {
                    "artefact_id"?: string | null,"centre_id"?: string,"created_at"?: string,"date"?: string,"id"?: string,"max"?: number,"photo_path"?: string | null,"questions"?: Json | null,"school_item_id"?: string | null,"score"?: number,"student_id"?: string,"subject"?: string,"test"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "marks_centre_id_artefact_id_fkey"
      columns: ["centre_id","artefact_id"]
isOneToOne: false
      referencedRelation: "artefacts"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "marks_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "marks_centre_id_school_item_id_fkey"
      columns: ["centre_id","school_item_id"]
isOneToOne: false
      referencedRelation: "school_items"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "marks_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"message_log": {
                  Row: {
                    "about_date": string | null,"body": string | null,"centre_id": string,"channel": Database["public"]['Enums']["message_channel"],"created_at": string,"id": string,"kind": Database["public"]['Enums']["message_kind"],"language": string | null,"opened_at": string,"student_id": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "about_date"?: string | null,"body"?: string | null,"centre_id": string,"channel"?: Database["public"]['Enums']["message_channel"],"created_at"?: string,"id"?: string,"kind": Database["public"]['Enums']["message_kind"],"language"?: string | null,"opened_at"?: string,"student_id"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "about_date"?: string | null,"body"?: string | null,"centre_id"?: string,"channel"?: Database["public"]['Enums']["message_channel"],"created_at"?: string,"id"?: string,"kind"?: Database["public"]['Enums']["message_kind"],"language"?: string | null,"opened_at"?: string,"student_id"?: string | null,"updated_at"?: string
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
                },"plan_items": {
                  Row: {
                    "artefact_id": string | null,"centre_id": string,"created_at": string,"done_at": string | null,"group_no": number | null,"id": string,"kind": Database["public"]['Enums']["plan_item_kind"],"moved_from": number | null,"plan_id": string,"skill_id": string | null,"skipped_at": string | null,"student_id": string | null,"updated_at": string,"words": string
                  }
                  ComputedFields: never
                  Insert: {
                    "artefact_id"?: string | null,"centre_id": string,"created_at"?: string,"done_at"?: string | null,"group_no"?: number | null,"id"?: string,"kind": Database["public"]['Enums']["plan_item_kind"],"moved_from"?: number | null,"plan_id": string,"skill_id"?: string | null,"skipped_at"?: string | null,"student_id"?: string | null,"updated_at"?: string,"words"?: string
                  }
                  Update: {
                    "artefact_id"?: string | null,"centre_id"?: string,"created_at"?: string,"done_at"?: string | null,"group_no"?: number | null,"id"?: string,"kind"?: Database["public"]['Enums']["plan_item_kind"],"moved_from"?: number | null,"plan_id"?: string,"skill_id"?: string | null,"skipped_at"?: string | null,"student_id"?: string | null,"updated_at"?: string,"words"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "plan_items_centre_id_artefact_id_fkey"
      columns: ["centre_id","artefact_id"]
isOneToOne: false
      referencedRelation: "artefacts"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "plan_items_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "plan_items_centre_id_plan_id_fkey"
      columns: ["centre_id","plan_id"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "plan_items_centre_id_skill_id_fkey"
      columns: ["centre_id","skill_id"]
isOneToOne: false
      referencedRelation: "skills"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "plan_items_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"plans": {
                  Row: {
                    "centre_id": string,"class_id": string | null,"created_at": string,"date": string,"groups": NonNullable<Json>,"id": string,"made_at": string,"session_id": string | null,"subjects": NonNullable<Json>,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"class_id"?: string | null,"created_at"?: string,"date": string,"groups"?: NonNullable<Json>,"id"?: string,"made_at"?: string,"session_id"?: string | null,"subjects"?: NonNullable<Json>,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"class_id"?: string | null,"created_at"?: string,"date"?: string,"groups"?: NonNullable<Json>,"id"?: string,"made_at"?: string,"session_id"?: string | null,"subjects"?: NonNullable<Json>,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "plans_centre_id_class_id_fkey"
      columns: ["centre_id","class_id"]
isOneToOne: false
      referencedRelation: "classes"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "plans_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "plans_centre_id_session_id_fkey"
      columns: ["centre_id","session_id"]
isOneToOne: false
      referencedRelation: "attendance_sessions"
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
                },"school_items": {
                  Row: {
                    "centre_id": string,"class_level": string | null,"confirmed_at": string | null,"created_at": string,"date": string,"end_date": string | null,"id": string,"kind": Database["public"]['Enums']["school_item_kind"],"photo_path": string | null,"portions": string | null,"received_at": string,"school_id": string | null,"source": string,"source_text": string | null,"student_id": string | null,"subject": string | null,"title": string,"updated_at": string,"window_days": number | null
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"class_level"?: string | null,"confirmed_at"?: string | null,"created_at"?: string,"date": string,"end_date"?: string | null,"id"?: string,"kind": Database["public"]['Enums']["school_item_kind"],"photo_path"?: string | null,"portions"?: string | null,"received_at"?: string,"school_id"?: string | null,"source"?: string,"source_text"?: string | null,"student_id"?: string | null,"subject"?: string | null,"title"?: string,"updated_at"?: string,"window_days"?: number | null
                  }
                  Update: {
                    "centre_id"?: string,"class_level"?: string | null,"confirmed_at"?: string | null,"created_at"?: string,"date"?: string,"end_date"?: string | null,"id"?: string,"kind"?: Database["public"]['Enums']["school_item_kind"],"photo_path"?: string | null,"portions"?: string | null,"received_at"?: string,"school_id"?: string | null,"source"?: string,"source_text"?: string | null,"student_id"?: string | null,"subject"?: string | null,"title"?: string,"updated_at"?: string,"window_days"?: number | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "school_items_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "school_items_centre_id_school_id_fkey"
      columns: ["centre_id","school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "school_items_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"schools": {
                  Row: {
                    "board": string | null,"centre_id": string,"created_at": string,"id": string,"name": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "board"?: string | null,"centre_id": string,"created_at"?: string,"id"?: string,"name": string,"updated_at"?: string
                  }
                  Update: {
                    "board"?: string | null,"centre_id"?: string,"created_at"?: string,"id"?: string,"name"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "schools_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    }
                  ]
                },"skills": {
                  Row: {
                    "centre_id": string,"chapter_id": string,"created_at": string,"id": string,"last_checked_at": string | null,"name": string,"position": number,"state": Database["public"]['Enums']["skill_state"],"state_at": string,"student_id": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"chapter_id": string,"created_at"?: string,"id"?: string,"last_checked_at"?: string | null,"name": string,"position": number,"state"?: Database["public"]['Enums']["skill_state"],"state_at"?: string,"student_id": string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"chapter_id"?: string,"created_at"?: string,"id"?: string,"last_checked_at"?: string | null,"name"?: string,"position"?: number,"state"?: Database["public"]['Enums']["skill_state"],"state_at"?: string,"student_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "skills_centre_id_chapter_id_fkey"
      columns: ["centre_id","chapter_id"]
isOneToOne: false
      referencedRelation: "chapters"
      referencedColumns: ["centre_id","id"]
    },{
      foreignKeyName: "skills_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "skills_centre_id_student_id_fkey"
      columns: ["centre_id","student_id"]
isOneToOne: false
      referencedRelation: "students"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"students": {
                  Row: {
                    "archived_at": string | null,"board": string | null,"centre_id": string,"class_id": string | null,"class_level": string | null,"consent_at": string | null,"consent_how": string | null,"consent_phone": string | null,"created_at": string,"date_of_birth": string | null,"gender": string | null,"id": string,"message_language": string,"monthly_fee": number | null,"name": string,"next_step": string | null,"notes": string | null,"parent_name": string | null,"parent_phone": string | null,"school_id": string | null,"track_reasons": NonNullable<Json>,"track_since": string | null,"track_status": string,"tracked_at": string | null,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"board"?: string | null,"centre_id": string,"class_id"?: string | null,"class_level"?: string | null,"consent_at"?: string | null,"consent_how"?: string | null,"consent_phone"?: string | null,"created_at"?: string,"date_of_birth"?: string | null,"gender"?: string | null,"id"?: string,"message_language"?: string,"monthly_fee"?: number | null,"name": string,"next_step"?: string | null,"notes"?: string | null,"parent_name"?: string | null,"parent_phone"?: string | null,"school_id"?: string | null,"track_reasons"?: NonNullable<Json>,"track_since"?: string | null,"track_status"?: string,"tracked_at"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "archived_at"?: string | null,"board"?: string | null,"centre_id"?: string,"class_id"?: string | null,"class_level"?: string | null,"consent_at"?: string | null,"consent_how"?: string | null,"consent_phone"?: string | null,"created_at"?: string,"date_of_birth"?: string | null,"gender"?: string | null,"id"?: string,"message_language"?: string,"monthly_fee"?: number | null,"name"?: string,"next_step"?: string | null,"notes"?: string | null,"parent_name"?: string | null,"parent_phone"?: string | null,"school_id"?: string | null,"track_reasons"?: NonNullable<Json>,"track_since"?: string | null,"track_status"?: string,"tracked_at"?: string | null,"updated_at"?: string
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
    },{
      foreignKeyName: "students_centre_id_school_id_fkey"
      columns: ["centre_id","school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["centre_id","id"]
    }
                  ]
                },"syllabi": {
                  Row: {
                    "blueprint": Json | null,"board": string,"chapters": NonNullable<Json>,"class_level": string,"created_at": string,"edition": string,"id": string,"subject": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "blueprint"?: Json | null,"board": string,"chapters"?: NonNullable<Json>,"class_level": string,"created_at"?: string,"edition": string,"id"?: string,"subject": string,"updated_at"?: string
                  }
                  Update: {
                    "blueprint"?: Json | null,"board"?: string,"chapters"?: NonNullable<Json>,"class_level"?: string,"created_at"?: string,"edition"?: string,"id"?: string,"subject"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    
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
                },"textbooks": {
                  Row: {
                    "centre_id": string,"chapters": NonNullable<Json>,"class_level": string,"created_at": string,"edition": string | null,"id": string,"photo_path": string | null,"publisher": string | null,"school_id": string,"subject": string,"title": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "centre_id": string,"chapters"?: NonNullable<Json>,"class_level": string,"created_at"?: string,"edition"?: string | null,"id"?: string,"photo_path"?: string | null,"publisher"?: string | null,"school_id": string,"subject": string,"title": string,"updated_at"?: string
                  }
                  Update: {
                    "centre_id"?: string,"chapters"?: NonNullable<Json>,"class_level"?: string,"created_at"?: string,"edition"?: string | null,"id"?: string,"photo_path"?: string | null,"publisher"?: string | null,"school_id"?: string,"subject"?: string,"title"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "textbooks_centre_id_fkey"
      columns: ["centre_id"]
isOneToOne: false
      referencedRelation: "centres"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "textbooks_centre_id_school_id_fkey"
      columns: ["centre_id","school_id"]
isOneToOne: false
      referencedRelation: "schools"
      referencedColumns: ["centre_id","id"]
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
"cancel_job":
{ Args: { "p_centre": string,"p_job": string }; Returns: boolean
                           },
"claim_jobs":
{ Args: { "p_lease_seconds"?: number,"p_limit"?: number,"p_worker": string }; Returns: {
              "attempts": number,
"centre_id": string | null,
"cost_paise": number,
"created_at": string,
"created_by": string | null,
"error": Json | null,
"finished_at": string | null,
"id": string,
"idempotency_key": string,
"input": NonNullable<Json>,
"kind": Database["public"]['Enums']["job_kind"],
"lease_until": string | null,
"leased_by": string | null,
"max_attempts": number,
"result": Json | null,
"run_at": string,
"started_at": string | null,
"state": Database["public"]['Enums']["job_state"],
"step": NonNullable<Json>,
"updated_at": string
            }[]
                          SetofOptions: {
        from: "*"
        to: "jobs"
        isOneToOne: false
        isSetofReturn: true
      } },
"close_session":
{ Args: { "p_centre": string,"p_checks": Json,"p_class": string,"p_date": string,"p_done"?: (string)[],"p_homework": Json,"p_marks": Json,"p_states"?: Json,"p_track": Json }; Returns: string
                           },
"copy_textbook_chapters":
{ Args: { "p_centre": string,"p_student": string,"p_textbook": string }; Returns: undefined
                           },
"copy_textbook_to_class":
{ Args: { "p_centre": string,"p_textbook": string }; Returns: number
                           },
"copy_textbooks_to_student":
{ Args: { "p_centre": string,"p_student": string }; Returns: number
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
"enqueue_job":
{ Args: { "p_centre": string,"p_input"?: Json,"p_key": string,"p_kind": Database["public"]['Enums']["job_kind"],"p_max_attempts"?: number,"p_run_at"?: string }; Returns: string
                           },
"extend_lease":
{ Args: { "p_job": string,"p_lease_seconds"?: number,"p_worker": string }; Returns: boolean
                           },
"fail_job":
{ Args: { "p_error": Json,"p_job": string,"p_retry": boolean,"p_worker": string }; Returns: Database["public"]['Enums']["job_state"]
                           },
"finish_job":
{ Args: { "p_job": string,"p_result": Json,"p_worker": string }; Returns: undefined
                           },
"generate_fees":
{ Args: { "p_centre": string,"p_period": string }; Returns: number
                           },
"is_member":
{ Args: { "c": string }; Returns: boolean
                           },
"job_held":
{ Args: { "p_job": string,"p_worker": string }; Returns: {
              "attempts": number,
"centre_id": string | null,
"cost_paise": number,
"created_at": string,
"created_by": string | null,
"error": Json | null,
"finished_at": string | null,
"id": string,
"idempotency_key": string,
"input": NonNullable<Json>,
"kind": Database["public"]['Enums']["job_kind"],
"lease_until": string | null,
"leased_by": string | null,
"max_attempts": number,
"result": Json | null,
"run_at": string,
"started_at": string | null,
"state": Database["public"]['Enums']["job_state"],
"step": NonNullable<Json>,
"updated_at": string
            }
                          SetofOptions: {
        from: "*"
        to: "jobs"
        isOneToOne: true
        isSetofReturn: false
      } },
"keep_artefact":
{ Args: { "p_artefact": Json,"p_centre": string,"p_group_no": number,"p_item_kind": Database["public"]['Enums']["plan_item_kind"],"p_made_from"?: string,"p_plan": string,"p_school_item"?: string,"p_student": string }; Returns: string
                           },
"make_plan":
{ Args: { "p_centre": string,"p_class": string,"p_date": string,"p_groups": Json,"p_items": Json,"p_subjects": Json }; Returns: Json
                           },
"name_plan_group":
{ Args: { "p_centre": string,"p_chapter": string,"p_group_no": number,"p_plan": string,"p_skill": string }; Returns: undefined
                           },
"photo_centre":
{ Args: { "p_name": string }; Returns: string
                           },
"record_placement":
{ Args: { "p_centre": string,"p_checks": Json,"p_states": Json,"p_student": string,"p_track": Json }; Returns: undefined
                           },
"record_step":
{ Args: { "p_cost_paise"?: number,"p_error"?: Json,"p_generation"?: string,"p_job": string,"p_state": Database["public"]['Enums']["job_state"],"p_step": string,"p_step_data"?: Json,"p_worker": string }; Returns: string
                           },
"save_attendance":
{ Args: { "p_centre": string,"p_class": string,"p_date": string,"p_marks": Json }; Returns: string
                           },
"start_ai_generation":
{ Args: { "p_centre": string,"p_input": Json,"p_kind": Database["public"]['Enums']["ai_kind"],"p_model": string,"p_student"?: string }; Returns: string
                           },
"wait_job":
{ Args: { "p_job": string,"p_run_at": string,"p_step": Json,"p_worker": string }; Returns: undefined
                           }
          }
          Enums: {
            "ai_kind": "paper"|"homework"|"worksheet"|"progress_note"|"scan_register"|"check_paper"|"plan"|"sheet"|"worked_example"|"figure"|"brief"|"check"|"placement"|"mock"|"note"|"can_do"|"test_tomorrow"|"gap_report"|"parse_school"|"parse_textbook"|"not_on_track"|"read_marks","ai_status": "ok"|"failed"|"pending","artefact_kind": "sheet"|"worked_example"|"figure"|"brief"|"check"|"placement"|"mock"|"note"|"can_do"|"test_tomorrow"|"gap_report","artefact_source": "made"|"own","attendance_status": "present"|"absent","centre_role": "owner"|"teacher","fee_status": "due"|"paid"|"waived","homework_status": "given"|"done"|"partial"|"not_done","job_kind": "plan"|"artefact"|"note_day"|"reminder_sweep"|"export"|"pdf"|"eval_run"|"sweep","job_state": "queued"|"running"|"waiting"|"done"|"failed"|"cancelled","message_channel": "whatsapp_link"|"copied","message_kind": "reminder"|"receipt"|"absence"|"progress"|"note"|"can_do"|"test_tomorrow"|"homework"|"consent"|"forward_ask"|"not_on_track","paid_method": "upi"|"cash"|"other","plan_item_kind": "teach"|"practise"|"check"|"homework"|"brief"|"catch_up"|"worked_example"|"figure","school_item_kind": "exam"|"homework"|"notice"|"holiday","skill_state": "not_started"|"taught"|"practising"|"secure"|"revisit"
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
            "ai_kind": ["paper", "homework", "worksheet", "progress_note", "scan_register", "check_paper", "plan", "sheet", "worked_example", "figure", "brief", "check", "placement", "mock", "note", "can_do", "test_tomorrow", "gap_report", "parse_school", "parse_textbook", "not_on_track", "read_marks"],"ai_status": ["ok", "failed", "pending"],"artefact_kind": ["sheet", "worked_example", "figure", "brief", "check", "placement", "mock", "note", "can_do", "test_tomorrow", "gap_report"],"artefact_source": ["made", "own"],"attendance_status": ["present", "absent"],"centre_role": ["owner", "teacher"],"fee_status": ["due", "paid", "waived"],"homework_status": ["given", "done", "partial", "not_done"],"job_kind": ["plan", "artefact", "note_day", "reminder_sweep", "export", "pdf", "eval_run", "sweep"],"job_state": ["queued", "running", "waiting", "done", "failed", "cancelled"],"message_channel": ["whatsapp_link", "copied"],"message_kind": ["reminder", "receipt", "absence", "progress", "note", "can_do", "test_tomorrow", "homework", "consent", "forward_ask", "not_on_track"],"paid_method": ["upi", "cash", "other"],"plan_item_kind": ["teach", "practise", "check", "homework", "brief", "catch_up", "worked_example", "figure"],"school_item_kind": ["exam", "homework", "notice", "holiday"],"skill_state": ["not_started", "taught", "practising", "secure", "revisit"]
          }
        }
} as const
