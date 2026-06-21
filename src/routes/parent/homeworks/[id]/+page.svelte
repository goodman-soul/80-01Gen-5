<script lang="ts">
	import type { PageData } from './$types';
	import type { AssignedHomework, HomeworkStep, Mood, StepCompletion, Video } from '$lib/types';
	import { ExerciseTypeLabels, ExerciseTypeColors, MoodLabels } from '$lib/types';
	import { Calendar, Clock, Upload, Play, Check, MessageCircle, Video as VideoIcon, ChevronRight } from 'lucide-svelte';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	export let data: PageData;

	let homework: AssignedHomework | null = null;
	let steps: HomeworkStep[] = [];
	let completedSteps: Record<string, boolean> = {};
	let loading = true;
	let notes = '';
	let mood: Mood | null = null;
	let uploading = false;
	let uploadingStepId: string | null = null;
	let uploadProgress = 0;
	let videos: Video[] = [];

	const moodList: Mood[] = ['happy', 'good', 'neutral', 'tired', 'unwilling'];

	$: allCompleted = steps.length > 0 && steps.every((s) => completedSteps[s.id]);
	$: completedCount = steps.filter((s) => completedSteps[s.id]).length;

	onMount(async () => {
		const homeworkId = data.params.id;
		const { data: hwData } = await data.supabase
			.from('assigned_homeworks')
			.select('*, child:children(*), template:homework_templates(steps:homework_steps(*))')
			.eq('id', homeworkId)
			.single();

		homework = hwData;
		if (hwData?.template?.steps) {
			steps = hwData.template.steps.sort((a, b) => a.step_number - b.step_number);
		}
		loading = false;
	});

	function toggleStep(stepId: string) {
		completedSteps = { ...completedSteps, [stepId]: !completedSteps[stepId] };
	}

	async function handleVideoUpload(e: Event, stepId: string) {
		const target = e.target as HTMLInputElement;
		const file = target.files?.[0];
		if (!file || !homework) return;

		uploading = true;
		uploadingStepId = stepId;
		uploadProgress = 0;

		try {
			const today = new Date().toISOString().split('T')[0];
			const filePath = `${homework.child_id}/${homework.id}/${today}/${Date.now()}-${file.name}`;

			const { error } = await data.supabase.storage
				.from('checkin-videos')
				.upload(filePath, file, {
					cacheControl: '3600',
					upsert: false
				});

			if (error) throw error;

			const checkInId = crypto.randomUUID();
			const stepCompletions: StepCompletion[] = Object.entries(completedSteps).map(
				([sid, completed]) => ({
					step_id: sid,
					completed,
					completed_at: completed ? new Date().toISOString() : undefined
				})
			);

			const { error: ciError, data: checkInData } = await data.supabase.from('check_ins').insert({
				id: checkInId,
				assigned_homework_id: homework.id,
				parent_id: data.session?.user.id,
				child_id: homework.child_id,
				check_in_date: today,
				completed_steps: stepCompletions,
				notes,
				mood
			}).select().single();

			if (ciError) throw ciError;

			const { error: vError } = await data.supabase.from('videos').insert({
				check_in_id: checkInId,
				step_id: stepId,
				storage_path: filePath,
				file_size: file.size,
				duration_seconds: 0
			});

			if (vError) throw vError;

			completedSteps[stepId] = true;
			completedSteps = { ...completedSteps };

			alert('视频上传成功！');
		} catch (err) {
			console.error(err);
			alert('上传失败，请重试');
		} finally {
			uploading = false;
			uploadingStepId = null;
			uploadProgress = 0;
			target.value = '';
		}
	}

	async function submitCheckIn() {
		if (!homework) return;

		const today = new Date().toISOString().split('T')[0];
		const stepCompletions: StepCompletion[] = steps.map((s) => ({
			step_id: s.id,
			completed: !!completedSteps[s.id],
			completed_at: completedSteps[s.id] ? new Date().toISOString() : undefined
		}));

		const { error } = await data.supabase.from('check_ins').insert({
			assigned_homework_id: homework.id,
			parent_id: data.session?.user.id,
			child_id: homework.child_id,
			check_in_date: today,
			completed_steps: stepCompletions,
			notes,
			mood
		});

		if (error) {
			console.error(error);
			alert('打卡失败，请重试');
			return;
		}

		alert('打卡成功！');
		await goto('/parent/checkins');
	}
</script>

<div class="max-w-4xl mx-auto px-4 py-8">
	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
		</div>
	{:else if !homework}
		<div class="card p-12 text-center">
			<p class="text-gray-500">作业不存在</p>
		</div>
	{:else}
		<div class="card p-6 mb-6">
			<div class="flex items-center gap-2 mb-3">
				<span class={`badge ${ExerciseTypeColors[homework.exercise_type]}`}>
					{ExerciseTypeLabels[homework.exercise_type]}
				</span>
				{#if homework.child}
					<span class="text-sm text-gray-500">为 {homework.child.name} 布置</span>
				{/if}
			</div>
			<h1 class="text-2xl font-bold text-gray-900 mb-2">{homework.title}</h1>
			{#if homework.description}
				<p class="text-gray-600 mb-4">{homework.description}</p>
			{/if}
			<div class="flex flex-wrap gap-4 text-sm text-gray-500">
				<span class="flex items-center">
					<Calendar class="w-4 h-4 mr-1" />
					{homework.start_date} ~ {homework.end_date}
				</span>
				<span class="flex items-center">
					<Clock class="w-4 h-4 mr-1" />
					每周 {homework.frequency_per_week} 次
				</span>
			</div>
		</div>

		<div class="card p-6 mb-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-semibold text-gray-900">训练步骤</h2>
				<span class="text-sm text-gray-500">{completedCount} / {steps.length} 已完成</span>
			</div>

			{#if steps.length === 0}
				<p class="text-gray-500 text-center py-4">暂无步骤</p>
			{:else}
				<div class="space-y-4">
					{#each steps as step, index}
						<div
							class={`border rounded-xl p-4 transition-all {
								completedSteps[step.id]
									? 'bg-green-50 border-green-200'
									: 'bg-white border-gray-200'
							}`}
						>
							<div class="flex items-start">
								<div class="mr-4">
									<button
										on:click={() => toggleStep(step.id)}
										class={`w-8 h-8 rounded-full flex items-center justify-center transition-colors {
											completedSteps[step.id]
												? 'bg-green-500 text-white'
												: 'border-2 border-gray-300 hover:border-primary-500'
										}`}
									>
										{#if completedSteps[step.id]}
											<Check class="w-5 h-5" />
										{:else}
											<span class="text-sm text-gray-400">{index + 1}</span>
										{/if}
									</button>
								</div>
								<div class="flex-1">
									<h3 class="font-medium text-gray-900 mb-1">
										第 {index + 1} 步：{step.title}
									</h3>
									{#if step.description}
										<p class="text-sm text-gray-600 mb-3">{step.description}</p>
									{/if}
									{#if step.duration_seconds > 0}
										<p class="text-xs text-gray-500 mb-3 flex items-center">
											<Clock class="w-3 h-3 mr-1" />
											建议时长：{Math.floor(step.duration_seconds / 60)}分{step.duration_seconds % 60}秒
										</p>
									{/if}
									<div class="flex items-center gap-3">
										<label
											class={`inline-flex items-center px-4 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors {
												uploadingStepId === step.id
													? 'bg-gray-200 text-gray-500'
													: 'bg-primary-500 text-white hover:bg-primary-600'
											}`}
										>
											{#if uploadingStepId === step.id}
												<div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
												上传中...
											{:else}
												<Upload class="w-4 h-4 mr-2" />
												上传视频
											{/if}
											<input
												type="file"
												accept="video/*"
												class="hidden"
												on:change={(e) => handleVideoUpload(e, step.id)}
												disabled={uploadingStepId === step.id}
											/>
										</label>
										{#if step.video_url}
											<button class="inline-flex items-center px-3 py-2 text-sm text-gray-600 hover:text-primary-600">
												<Play class="w-4 h-4 mr-1" />
												参考视频
											</button>
										{/if}
									</div>
								</div>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<div class="card p-6 mb-6">
			<h2 class="text-lg font-semibold text-gray-900 mb-4">今日反馈</h2>
			<div class="mb-4">
				<label class="label">孩子情绪</label>
				<div class="flex flex-wrap gap-2">
					{#each moodList as m}
						<button
							type="button"
							on:click={() => (mood = mood === m ? null : m)}
							class={`px-4 py-2 rounded-lg text-sm font-medium transition-colors border {
								mood === m
									? 'bg-primary-500 text-white border-primary-500'
									: 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
							}`}
						>
							{MoodLabels[m]}
						</button>
					{/each}
				</div>
			</div>
			<div>
				<label class="label">备注</label>
				<textarea
					bind:value={notes}
					class="input min-h-[100px]"
					placeholder="记录训练过程中的情况和问题..."
				/>
			</div>
		</div>

		<div class="sticky bottom-4">
			<button
				on:click={submitCheckIn}
				class="btn btn-primary w-full text-lg py-3"
				disabled={completedCount === 0}
			>
				<Check class="w-5 h-5 mr-2" />
				提交打卡 ({completedCount}/{steps.length} 步骤)
			</button>
		</div>
	{/if}
</div>
