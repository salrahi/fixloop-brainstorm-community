export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      account_suspensions: {
        Row: {
          created_at: string
          reason: string
          suspended_by: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          reason?: string
          suspended_by?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          reason?: string
          suspended_by?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "account_suspensions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_requests: {
        Row: {
          created_at: string
          id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      answer_likes: {
        Row: {
          answer_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          answer_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          answer_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "answer_likes_answer_id_fkey"
            columns: ["answer_id"]
            isOneToOne: false
            referencedRelation: "answers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "answer_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      answers: {
        Row: {
          author_id: string
          body: string
          comment_count: number
          created_at: string
          helpful_count: number
          id: string
          is_removed: boolean
          like_count: number
          question_id: string
          search: unknown
          updated_at: string
        }
        Insert: {
          author_id: string
          body: string
          comment_count?: number
          created_at?: string
          helpful_count?: number
          id?: string
          is_removed?: boolean
          like_count?: number
          question_id: string
          search?: unknown
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string
          comment_count?: number
          created_at?: string
          helpful_count?: number
          id?: string
          is_removed?: boolean
          like_count?: number
          question_id?: string
          search?: unknown
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "answers_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "answers_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "questions"
            referencedColumns: ["id"]
          },
        ]
      }
      blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "blocks_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocks_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          created_at: string
          description: string
          name: string
          slug: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          description?: string
          name: string
          slug: string
          sort_order?: number
        }
        Update: {
          created_at?: string
          description?: string
          name?: string
          slug?: string
          sort_order?: number
        }
        Relationships: []
      }
      comments: {
        Row: {
          answer_id: string
          author_id: string
          body: string
          created_at: string
          id: string
          is_removed: boolean
          updated_at: string
        }
        Insert: {
          answer_id: string
          author_id: string
          body: string
          created_at?: string
          id?: string
          is_removed?: boolean
          updated_at?: string
        }
        Update: {
          answer_id?: string
          author_id?: string
          body?: string
          created_at?: string
          id?: string
          is_removed?: boolean
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_answer_id_fkey"
            columns: ["answer_id"]
            isOneToOne: false
            referencedRelation: "answers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      feedback: {
        Row: {
          created_at: string
          id: string
          message: string
          page: string
          user_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          message: string
          page?: string
          user_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          message?: string
          page?: string
          user_id?: string | null
        }
        Relationships: []
      }
      helpful_votes: {
        Row: {
          answer_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          answer_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          answer_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "helpful_votes_answer_id_fkey"
            columns: ["answer_id"]
            isOneToOne: false
            referencedRelation: "answers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "helpful_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          actor_id: string | null
          answer_id: string | null
          created_at: string
          id: string
          question_id: string | null
          read_at: string | null
          type: string
          user_id: string
        }
        Insert: {
          actor_id?: string | null
          answer_id?: string | null
          created_at?: string
          id?: string
          question_id?: string | null
          read_at?: string | null
          type: string
          user_id: string
        }
        Update: {
          actor_id?: string | null
          answer_id?: string | null
          created_at?: string
          id?: string
          question_id?: string | null
          read_at?: string | null
          type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_answer_id_fkey"
            columns: ["answer_id"]
            isOneToOne: false
            referencedRelation: "answers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string
          created_at: string
          display_name: string
          id: string
          interests: string[]
          updated_at: string
          username: string
        }
        Insert: {
          avatar_url?: string | null
          bio?: string
          created_at?: string
          display_name?: string
          id: string
          interests?: string[]
          updated_at?: string
          username: string
        }
        Update: {
          avatar_url?: string | null
          bio?: string
          created_at?: string
          display_name?: string
          id?: string
          interests?: string[]
          updated_at?: string
          username?: string
        }
        Relationships: []
      }
      question_likes: {
        Row: {
          created_at: string
          question_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          question_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          question_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "question_likes_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "question_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      questions: {
        Row: {
          accepted_answer_id: string | null
          answer_count: number
          author_id: string
          body: string
          category_slug: string
          created_at: string
          helpful_count: number
          id: string
          is_removed: boolean
          like_count: number
          search: unknown
          tags: string[]
          title: string
          updated_at: string
        }
        Insert: {
          accepted_answer_id?: string | null
          answer_count?: number
          author_id: string
          body: string
          category_slug: string
          created_at?: string
          helpful_count?: number
          id?: string
          is_removed?: boolean
          like_count?: number
          search?: unknown
          tags?: string[]
          title: string
          updated_at?: string
        }
        Update: {
          accepted_answer_id?: string | null
          answer_count?: number
          author_id?: string
          body?: string
          category_slug?: string
          created_at?: string
          helpful_count?: number
          id?: string
          is_removed?: boolean
          like_count?: number
          search?: unknown
          tags?: string[]
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "questions_accepted_answer_fk"
            columns: ["accepted_answer_id"]
            isOneToOne: false
            referencedRelation: "answers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "questions_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "questions_category_slug_fkey"
            columns: ["category_slug"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["slug"]
          },
        ]
      }
      quiz_attempt_answers: {
        Row: {
          answered_at: string
          attempt_id: string
          choice: number
          is_correct: boolean
          question_id: string
        }
        Insert: {
          answered_at?: string
          attempt_id: string
          choice: number
          is_correct: boolean
          question_id: string
        }
        Update: {
          answered_at?: string
          attempt_id?: string
          choice?: number
          is_correct?: boolean
          question_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_attempt_answers_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "quiz_attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quiz_attempt_answers_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "quiz_questions"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_attempts: {
        Row: {
          answered: number
          challenge_date: string | null
          completed_at: string | null
          created_at: string
          difficulty: string | null
          id: string
          mode: string
          question_ids: string[]
          score: number
          topic: string | null
          total: number
          user_id: string
        }
        Insert: {
          answered?: number
          challenge_date?: string | null
          completed_at?: string | null
          created_at?: string
          difficulty?: string | null
          id?: string
          mode: string
          question_ids: string[]
          score?: number
          topic?: string | null
          total: number
          user_id: string
        }
        Update: {
          answered?: number
          challenge_date?: string | null
          completed_at?: string | null
          created_at?: string
          difficulty?: string | null
          id?: string
          mode?: string
          question_ids?: string[]
          score?: number
          topic?: string | null
          total?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_attempts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_questions: {
        Row: {
          correct_index: number
          created_at: string
          difficulty: string
          explanation: string
          id: string
          is_active: boolean
          kind: string
          options: string[]
          prompt: string
          topic: string
        }
        Insert: {
          correct_index: number
          created_at?: string
          difficulty: string
          explanation?: string
          id?: string
          is_active?: boolean
          kind: string
          options: string[]
          prompt: string
          topic: string
        }
        Update: {
          correct_index?: number
          created_at?: string
          difficulty?: string
          explanation?: string
          id?: string
          is_active?: boolean
          kind?: string
          options?: string[]
          prompt?: string
          topic?: string
        }
        Relationships: []
      }
      reports: {
        Row: {
          answer_id: string | null
          comment_id: string | null
          created_at: string
          details: string
          id: string
          question_id: string | null
          reason: string
          reported_user_id: string | null
          reporter_id: string
          resolved_at: string | null
          resolved_by: string | null
          status: string
          target_type: string
        }
        Insert: {
          answer_id?: string | null
          comment_id?: string | null
          created_at?: string
          details?: string
          id?: string
          question_id?: string | null
          reason: string
          reported_user_id?: string | null
          reporter_id: string
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          target_type: string
        }
        Update: {
          answer_id?: string | null
          comment_id?: string | null
          created_at?: string
          details?: string
          id?: string
          question_id?: string | null
          reason?: string
          reported_user_id?: string | null
          reporter_id?: string
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          target_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "reports_answer_id_fkey"
            columns: ["answer_id"]
            isOneToOne: false
            referencedRelation: "answers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_reported_user_id_fkey"
            columns: ["reported_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_ai_responses: {
        Row: {
          category_slug: string | null
          created_at: string
          id: string
          prompt: string
          response: string
          user_id: string
        }
        Insert: {
          category_slug?: string | null
          created_at?: string
          id?: string
          prompt: string
          response: string
          user_id: string
        }
        Update: {
          category_slug?: string | null
          created_at?: string
          id?: string
          prompt?: string
          response?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_ai_responses_category_slug_fkey"
            columns: ["category_slug"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["slug"]
          },
          {
            foreignKeyName: "saved_ai_responses_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_questions: {
        Row: {
          created_at: string
          question_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          question_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          question_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_questions_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "saved_questions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_list_users: {
        Args: { _search?: string }
        Returns: {
          answer_count: number
          avatar_url: string
          created_at: string
          display_name: string
          id: string
          is_admin: boolean
          is_suspended: boolean
          question_count: number
          username: string
        }[]
      }
      admin_set_removed: {
        Args: { _id: string; _removed: boolean; _type: string }
        Returns: undefined
      }
      answer_attempt: {
        Args: { _attempt_id: string; _choice: number; _question_id: string }
        Returns: Json
      }
      attempt_payload: { Args: { _attempt_id: string }; Returns: Json }
      create_notification: {
        Args: {
          _actor: string
          _answer: string
          _question: string
          _recipient: string
          _type: string
        }
        Returns: undefined
      }
      get_leaderboard: {
        Args: { _period?: string }
        Returns: {
          avatar_url: string
          display_name: string
          points: number
          rounds: number
          username: string
        }[]
      }
      get_my_arena_stats: { Args: never; Returns: Json }
      get_platform_stats: { Args: never; Returns: Json }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_active_user: { Args: { _user_id: string }; Returns: boolean }
      is_username_available: { Args: { _username: string }; Returns: boolean }
      search_answers: {
        Args: { _q: string }
        Returns: {
          author_id: string
          body: string
          comment_count: number
          created_at: string
          helpful_count: number
          id: string
          is_removed: boolean
          like_count: number
          question_id: string
          search: unknown
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "answers"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      search_questions: {
        Args: { _category?: string; _q: string }
        Returns: {
          accepted_answer_id: string | null
          answer_count: number
          author_id: string
          body: string
          category_slug: string
          created_at: string
          helpful_count: number
          id: string
          is_removed: boolean
          like_count: number
          search: unknown
          tags: string[]
          title: string
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "questions"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      start_attempt: {
        Args: { _difficulty?: string; _mode: string; _topic?: string }
        Returns: Json
      }
    }
    Enums: {
      app_role: "admin" | "moderator" | "user"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
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
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
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
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "moderator", "user"],
    },
  },
} as const
