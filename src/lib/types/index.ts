export type UserRole = 'admin' | 'therapist' | 'parent';

export type ExerciseType = 'pronunciation' | 'fine_motor' | 'sensory';

export type HomeworkStatus = 'pending' | 'in_progress' | 'completed' | 'reviewed';

export type Mood = 'happy' | 'good' | 'neutral' | 'tired' | 'unwilling';

export interface Institution {
	id: string;
	name: string;
	address: string | null;
	contact_phone: string | null;
	created_at: string;
	updated_at: string;
}

export interface Profile {
	id: string;
	full_name: string;
	phone: string | null;
	avatar_url: string | null;
	role: UserRole;
	institution_id: string | null;
	created_at: string;
	updated_at: string;
}

export interface Child {
	id: string;
	name: string;
	nickname: string | null;
	birth_date: string | null;
	gender: 'male' | 'female' | 'other' | null;
	avatar_url: string | null;
	notes: string | null;
	parent_id: string;
	therapist_id: string | null;
	created_at: string;
	updated_at: string;
}

export interface HomeworkTemplate {
	id: string;
	title: string;
	description: string | null;
	exercise_type: ExerciseType;
	therapist_id: string;
	institution_id: string | null;
	is_public: boolean;
	created_at: string;
	updated_at: string;
	steps?: HomeworkStep[];
}

export interface HomeworkStep {
	id: string;
	template_id: string;
	step_number: number;
	title: string;
	description: string | null;
	image_url: string | null;
	video_url: string | null;
	duration_seconds: number;
	created_at: string;
	updated_at: string;
}

export interface AssignedHomework {
	id: string;
	template_id: string | null;
	child_id: string;
	therapist_id: string;
	title: string;
	description: string | null;
	exercise_type: ExerciseType;
	start_date: string;
	end_date: string;
	frequency_per_week: number;
	status: HomeworkStatus;
	created_at: string;
	updated_at: string;
	child?: Child;
	steps?: HomeworkStep[];
}

export interface StepCompletion {
	step_id: string;
	completed: boolean;
	completed_at?: string;
}

export interface CheckIn {
	id: string;
	assigned_homework_id: string;
	parent_id: string;
	child_id: string;
	check_in_date: string;
	completed_steps: StepCompletion[];
	notes: string | null;
	mood: Mood | null;
	created_at: string;
	updated_at: string;
	videos?: Video[];
	review?: Review;
}

export interface Video {
	id: string;
	check_in_id: string;
	step_id: string | null;
	storage_path: string;
	thumbnail_url: string | null;
	duration_seconds: number | null;
	file_size: number | null;
	created_at: string;
	public_url?: string;
}

export interface StepReview {
	step_id: string;
	correct: boolean;
	feedback: string;
}

export interface VideoAnnotation {
	time: number;
	comment: string;
}

export interface Review {
	id: string;
	check_in_id: string;
	therapist_id: string;
	overall_rating: number | null;
	action_correct: boolean | null;
	feedback: string | null;
	next_adjustment: string | null;
	step_reviews: StepReview[];
	video_annotations: VideoAnnotation[];
	created_at: string;
	updated_at: string;
}

export const ExerciseTypeLabels: Record<ExerciseType, string> = {
	pronunciation: '发音练习',
	fine_motor: '精细动作',
	sensory: '感统练习'
};

export const ExerciseTypeColors: Record<ExerciseType, string> = {
	pronunciation: 'bg-blue-100 text-blue-700',
	fine_motor: 'bg-green-100 text-green-700',
	sensory: 'bg-purple-100 text-purple-700'
};

export const HomeworkStatusLabels: Record<HomeworkStatus, string> = {
	pending: '待开始',
	in_progress: '进行中',
	completed: '已完成',
	reviewed: '已评审'
};

export const MoodLabels: Record<Mood, string> = {
	happy: '开心',
	good: '良好',
	neutral: '一般',
	tired: '疲惫',
	unwilling: '不愿意'
};
