<script lang="ts">
	import type { PageData } from './$types';
	import type { CheckIn, Review, StepReview, Video, VideoAnnotation, Child, HomeworkStep } from '$lib/types';
	import { MoodLabels } from '$lib/types';
	import { ArrowLeft, Star, Save, Play, Video as VideoIcon, MessageSquare, ThumbsUp, ThumbsDown, Plus, Trash2, Clock } from 'lucide-svelte';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	export let data: PageData;

	let checkIn: (CheckIn & {
		homework?: { title: string; exercise_type: string; template?: { steps: HomeworkStep[] } };
		child?: Child;
		videos?: Video[];
	}) | null = null;
	let existingReview: Review | null = null;
	let loading = true;

	let overallRating = 0;
	let hoverRating = 0;
	let actionCorrect: boolean | null = null;
	let feedback = '';
	let nextAdjustment = '';
	let stepReviews: StepReview[] = [];
	let videoAnnotations: VideoAnnotation[] = [];
	let newAnnotationTime = '';
	let newAnnotationComment = '';

	onMount(async () => {
		const checkInId = data.params.id;

		const { data: ciData } = await data.supabase
			.from('check_ins')
			.select(`
				*,
				homework:assigned_homeworks(
					title,
					exercise_type,
					template:homework_templates(
						steps:homework_steps(*)
					)
				),
				child:children(name, nickname),
				videos(*),
				review:reviews(*)
			`)
			.eq('id', checkInId)
			.single();

		checkIn = ciData;

		if (ciData?.review?.[0]) {
			existingReview = ciData.review[0];
			overallRating = existingReview.overall_rating || 0;
			actionCorrect = existingReview.action_correct;
			feedback = existingReview.feedback || '';
			nextAdjustment = existingReview.next_adjustment || '';
			stepReviews = existingReview.step_reviews || [];
			videoAnnotations = existingReview.video_annotations || [];
		}

		const templateSteps = ciData?.homework?.template?.steps || [];
		if (stepReviews.length === 0 && templateSteps.length > 0) {
			stepReviews = templateSteps
				.sort((a, b) => a.step_number - b.step_number)
				.map((s) => ({ step_id: s.id, correct: false, feedback: '' }));
		}

		loading = false;
	});

	function addAnnotation() {
		if (!newAnnotationComment.trim()) return;
		const time = parseFloat(newAnnotationTime) || 0;
		videoAnnotations = [
			...videoAnnotations,
			{ time, comment: newAnnotationComment.trim() }
		].sort((a, b) => a.time - b.time);
		newAnnotationTime = '';
		newAnnotationComment = '';
	}

	function removeAnnotation(index: number) {
		videoAnnotations = videoAnnotations.filter((_, i) => i !== index);
	}

	function formatTime(seconds: number): string {
		const m = Math.floor(seconds / 60);
		const s = Math.floor(seconds % 60);
		return `${m}:${s.toString().padStart(2, '0')}`;
	}

	async function saveReview() {
		if (!checkIn) return;

		if (overallRating === 0) {
			alert('请给出总体评分');
			return;
		}

		const { error } = await data.supabase.from('reviews').upsert({
			check_in_id: checkIn.id,
			therapist_id: data.profile?.id,
			overall_rating: overallRating,
			action_correct: actionCorrect,
			feedback,
			next_adjustment: nextAdjustment,
			step_reviews: stepReviews,
			video_annotations: videoAnnotations
		}, {
			onConflict: 'check_in_id,therapist_id'
		});

		if (error) {
			console.error(error);
			alert('保存失败，请重试');
			return;
		}

		alert('评审保存成功！');
		await goto('/therapist/reviews');
	}

	function getStepTitle(stepId: string): string {
		const steps = checkIn?.homework?.template?.steps || [];
		const step = steps.find((s) => s.id === stepId);
		if (step) return `第${step.step_number}步：${step.title}`;
		return stepId;
	}
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="flex items-center mb-6">
		<button on:click={() => history.back()} class="p-2 hover:bg-gray-100 rounded-lg mr-2">
			<ArrowLeft class="w-5 h-5" />
		</button>
		<div>
			<h1 class="text-2xl font-bold text-gray-900">打卡评审</h1>
			{#if checkIn?.child}
				<p class="text-gray-500 text-sm">
					{checkIn.child.name} {checkIn.child.nickname ? `(${checkIn.child.nickname})` : ''} · {checkIn.homework?.title}
				</p>
			{/if}
		</div>
		{#if existingReview}
			<span class="ml-auto badge bg-green-100 text-green-700">已评审</span>
		{/if}
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
		</div>
	{:else if !checkIn}
		<div class="card p-12 text-center">
			<p class="text-gray-500">打卡记录不存在</p>
		</div>
	{:else}
		<div class="grid lg:grid-cols-2 gap-6">
			<div class="space-y-6">
				<div class="card p-6">
					<h2 class="text-lg font-semibold text-gray-900 mb-4">打卡信息</h2>
					<div class="space-y-3 text-sm">
						<div class="flex justify-between">
							<span class="text-gray-500">打卡时间</span>
							<span class="text-gray-900">{new Date(checkIn.created_at).toLocaleString('zh-CN')}</span>
						</div>
						<div class="flex justify-between">
							<span class="text-gray-500">孩子情绪</span>
							<span class="text-gray-900">
								{checkIn.mood ? MoodLabels[checkIn.mood] : '未记录'}
							</span>
						</div>
						{#if checkIn.notes}
							<div>
								<p class="text-gray-500 mb-1">家长备注</p>
								<div class="p-3 bg-gray-50 rounded-lg text-gray-700">{checkIn.notes}</div>
							</div>
						{/if}
					</div>
				</div>

				<div class="card p-6">
					<h2 class="text-lg font-semibold text-gray-900 mb-4">
						视频记录 ({checkIn.videos?.length || 0})
					</h2>
					{#if !checkIn.videos || checkIn.videos.length === 0}
						<p class="text-gray-500 text-center py-4">暂无视频</p>
					{:else}
						<div class="space-y-3">
							{#each checkIn.videos as video, i}
								<div class="bg-gray-900 rounded-xl overflow-hidden aspect-video flex items-center justify-center relative">
									<div class="absolute inset-0 bg-gradient-to-b from-transparent to-black/30" />
									<div class="text-center z-10">
										<div class="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-2">
											<Play class="w-8 h-8 text-white ml-1" />
										</div>
										<p class="text-white text-sm">视频 {i + 1}</p>
										{#if video.duration_seconds}
											<p class="text-white/70 text-xs">{formatTime(video.duration_seconds)}</p>
										{/if}
									</div>
								</div>
							{/each}
						</div>
					{/if}
				</div>

				<div class="card p-6">
					<h2 class="text-lg font-semibold text-gray-900 mb-4">视频时间点标注</h2>
					<div class="mb-4 p-4 bg-gray-50 rounded-xl">
						<p class="text-sm text-gray-600 mb-3">在视频特定时间点添加标注，方便家长定位问题</p>
						<div class="flex gap-2">
							<input
								type="number"
								bind:value={newAnnotationTime}
								placeholder="时间(秒)"
								min="0"
								class="input w-28 text-sm"
							/>
							<input
								type="text"
								bind:value={newAnnotationComment}
								placeholder="标注说明..."
								class="input flex-1 text-sm"
								on:keydown={(e) => e.key === 'Enter' && addAnnotation()}
							/>
							<button on:click={addAnnotation} class="btn btn-primary text-sm">
								<Plus class="w-4 h-4" />
							</button>
						</div>
					</div>

					{#if videoAnnotations.length === 0}
						<p class="text-gray-400 text-center py-4 text-sm">暂无时间点标注</p>
					{:else}
						<div class="space-y-2">
							{#each videoAnnotations as ann, i}
								<div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
									<div class="w-12 h-8 bg-primary-100 rounded flex items-center justify-center text-primary-700 font-mono text-sm font-medium">
										{formatTime(ann.time)}
									</div>
									<p class="flex-1 text-sm text-gray-700">{ann.comment}</p>
									<button
										on:click={() => removeAnnotation(i)}
										class="p-1 text-gray-400 hover:text-red-500"
									>
										<Trash2 class="w-4 h-4" />
									</button>
								</div>
							{/each}
						</div>
					{/if}
				</div>
			</div>

			<div class="space-y-6">
				<div class="card p-6">
					<h2 class="text-lg font-semibold text-gray-900 mb-4">总体评分</h2>
					<div class="flex items-center gap-2 mb-6">
						{#each [1, 2, 3, 4, 5] as n}
							<button
								on:click={() => (overallRating = n)}
								on:mouseenter={() => (hoverRating = n)}
								on:mouseleave={() => (hoverRating = 0)}
								class="p-1 transition-transform hover:scale-110"
							>
								<Star
									class={`w-10 h-10 transition-colors {
										(hoverRating || overallRating) >= n
											? 'text-yellow-400 fill-yellow-400'
											: 'text-gray-300'
									}`}
								/>
							</button>
						{/each}
						<span class="ml-2 text-lg font-medium text-gray-700">
							{overallRating > 0 ? `${overallRating}/5` : '点击评分'}
						</span>
					</div>

					<div class="mb-6">
						<label class="label mb-3">动作是否到位？</label>
						<div class="flex gap-3">
							<button
								type="button"
								on:click={() => (actionCorrect = true)}
								class={`flex-1 px-4 py-3 rounded-xl font-medium transition-all border-2 {
									actionCorrect === true
										? 'bg-green-500 text-white border-green-500'
										: 'bg-white text-gray-700 border-gray-300 hover:border-green-400'
								}`}
							>
								<ThumbsUp class="w-5 h-5 inline-block mr-2" />
								到位
							</button>
							<button
								type="button"
								on:click={() => (actionCorrect = false)}
								class={`flex-1 px-4 py-3 rounded-xl font-medium transition-all border-2 {
									actionCorrect === false
										? 'bg-red-500 text-white border-red-500'
										: 'bg-white text-gray-700 border-gray-300 hover:border-red-400'
								}`}
							>
								<ThumbsDown class="w-5 h-5 inline-block mr-2" />
								需改进
							</button>
						</div>
					</div>

					<div class="mb-6">
						<label class="label">整体反馈 *</label>
						<textarea
							bind:value={feedback}
							class="input min-h-[120px]"
							placeholder="评价本次训练的整体表现，指出做得好的地方和需要改进的地方..."
						/>
					</div>

					<div>
						<label class="label">下次训练调整建议</label>
						<textarea
							bind:value={nextAdjustment}
							class="input min-h-[100px]"
							placeholder="针对本次训练情况，给出下次训练的调整建议，如增加难度、更换动作、延长时间等..."
						/>
					</div>
				</div>

				<div class="card p-6">
					<h2 class="text-lg font-semibold text-gray-900 mb-4">分步骤评估</h2>
					{#if stepReviews.length === 0}
						<p class="text-gray-500 text-center py-4">暂无步骤信息</p>
					{:else}
						<div class="space-y-4">
							{#each stepReviews as sr, i}
								<div class="border border-gray-200 rounded-xl p-4">
									<div class="flex items-center justify-between mb-3">
										<p class="font-medium text-gray-900">{getStepTitle(sr.step_id)}</p>
										<div class="flex gap-2">
											<button
												type="button"
												on:click={() => (sr.correct = true)}
												class={`px-3 py-1 rounded-lg text-xs font-medium transition-colors {
													sr.correct
														? 'bg-green-500 text-white'
														: 'bg-gray-100 text-gray-600 hover:bg-green-100'
												}`}
											>
												达标
											</button>
											<button
												type="button"
												on:click={() => (sr.correct = false)}
												class={`px-3 py-1 rounded-lg text-xs font-medium transition-colors {
													!sr.correct
														? 'bg-orange-500 text-white'
														: 'bg-gray-100 text-gray-600 hover:bg-orange-100'
												}`}
											>
												待加强
											</button>
										</div>
									</div>
									<input
										type="text"
										bind:value={sr.feedback}
										class="input text-sm"
										placeholder="针对本步骤的具体反馈..."
									/>
								</div>
							{/each}
						</div>
					{/if}
				</div>

				<div class="sticky bottom-4">
					<button on:click={saveReview} class="btn btn-primary w-full text-lg py-3">
						<Save class="w-5 h-5 mr-2" />
						{existingReview ? '更新评审' : '提交评审'}
					</button>
				</div>
			</div>
		</div>
	{/if}
</div>
