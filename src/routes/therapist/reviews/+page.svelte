<script lang="ts">
	import type { PageData } from './$types';
	import type { CheckIn, Child, Review, StepReview, Video, VideoAnnotation } from '$lib/types';
	import { MoodLabels } from '$lib/types';
	import { Video as VideoIcon, Star, MessageCircle, Search, Clock, User } from 'lucide-svelte';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	export let data: PageData;

	let checkIns: (CheckIn & {
		homework?: { title: string; exercise_type: string };
		child?: Child;
		review?: Review;
		videos?: Video[];
	})[] = [];
	let loading = true;
	let searchQuery = '';
	let showOnlyPending = true;

	$: filteredCheckIns = checkIns.filter((ci) => {
		const matchSearch =
			ci.child?.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
			ci.homework?.title.toLowerCase().includes(searchQuery.toLowerCase());
		const matchPending = showOnlyPending ? !ci.review : true;
		return matchSearch && matchPending;
	});

	onMount(async () => {
		if (!data.profile) return;

		const patientIds = (data.patients || []).map((p) => p.id);
		if (patientIds.length === 0) {
			loading = false;
			return;
		}

		const { data: ciData } = await data.supabase
			.from('check_ins')
			.select('*, homework:assigned_homeworks(title, exercise_type), child:children(name, nickname), review:reviews(*), videos(*)')
			.in('child_id', patientIds)
			.order('created_at', { ascending: false });

		checkIns = ciData || [];
		loading = false;
	});

	function getMoodEmoji(mood: string | null) {
		switch (mood) {
			case 'happy':
				return '😊';
			case 'good':
				return '🙂';
			case 'neutral':
				return '😐';
			case 'tired':
				return '😴';
			case 'unwilling':
				return '😟';
			default:
				return '';
		}
	}
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">打卡评审</h1>
			<p class="text-gray-500 text-sm">
				共 {checkIns.length} 条打卡，{checkIns.filter((ci) => !ci.review).length} 条待评审
			</p>
		</div>
	</div>

	<div class="flex flex-col sm:flex-row gap-4 mb-6">
		<div class="relative flex-1 max-w-sm">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
			<input
				type="text"
				bind:value={searchQuery}
				class="input pl-10 w-full"
				placeholder="搜索患者或作业..."
			/>
		</div>
		<label class="flex items-center">
			<input
				type="checkbox"
				bind:checked={showOnlyPending}
				class="w-4 h-4 text-primary-600 rounded border-gray-300 focus:ring-primary-500"
			/>
			<span class="ml-2 text-sm text-gray-700">只看待评审</span>
		</label>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
		</div>
	{:else if filteredCheckIns.length === 0}
		<div class="card p-12 text-center">
			<VideoIcon class="w-16 h-16 text-gray-300 mx-auto mb-4" />
			<p class="text-gray-500 mb-2">
				{showOnlyPending ? '暂无待评审的打卡' : '暂无打卡记录'}
			</p>
			<p class="text-sm text-gray-400">
				{showOnlyPending ? '所有打卡都已完成评审，做得好！' : '家长完成打卡后会显示在这里'}
			</p>
		</div>
	{:else}
		<div class="space-y-4">
			{#each filteredCheckIns as ci}
				<a
					href={`/therapist/reviews/${ci.id}`}
					class="card p-6 block hover:shadow-md transition-shadow"
				>
					<div class="flex items-start justify-between">
						<div class="flex-1">
							<div class="flex items-center gap-2 mb-2">
								{#if !ci.review}
									<span class="badge bg-orange-100 text-orange-700 animate-pulse">待评审</span>
								{:else}
									<span class="badge bg-green-100 text-green-700">已评审</span>
								{/if}
								{#if ci.child}
									<div class="flex items-center text-sm text-gray-600">
										<div class="w-5 h-5 bg-primary-100 rounded-full mr-1.5 flex items-center justify-center text-xs text-primary-600 font-medium">
											{ci.child.name[0]}
										</div>
										{ci.child.name}
										{#if ci.child.nickname}
											<span class="text-gray-400 ml-1">({ci.child.nickname})</span>
										{/if}
									</div>
								{/if}
							</div>

							<h3 class="text-lg font-semibold text-gray-900 mb-1">
								{ci.homework?.title || '训练打卡'}
							</h3>

							<div class="flex flex-wrap items-center gap-4 text-sm text-gray-500">
								<span class="flex items-center">
									<Clock class="w-4 h-4 mr-1" />
									{new Date(ci.created_at).toLocaleString('zh-CN')}
								</span>
								{#if ci.mood}
									<span>
										{getMoodEmoji(ci.mood)} {MoodLabels[ci.mood]}
									</span>
								{/if}
								{#if ci.videos && ci.videos.length > 0}
									<span class="flex items-center">
										<VideoIcon class="w-4 h-4 mr-1" />
										{ci.videos.length} 个视频
									</span>
								{/if}
								{#if ci.review?.overall_rating}
									<span class="flex items-center">
										<Star class="w-4 h-4 mr-1 text-yellow-500 fill-yellow-500" />
										{ci.review.overall_rating}/5
									</span>
								{/if}
							</div>

							{#if ci.notes}
								<p class="text-sm text-gray-600 mt-3 p-3 bg-gray-50 rounded-lg line-clamp-2">
									{ci.notes}
								</p>
							{/if}

							{#if ci.review?.feedback}
								<div class="mt-3 p-3 bg-green-50 rounded-lg">
									<p class="text-xs text-green-700 font-medium mb-1">我的反馈：</p>
									<p class="text-sm text-gray-700 line-clamp-2">{ci.review.feedback}</p>
								</div>
							{/if}
						</div>
					</div>
				</a>
			{/each}
		</div>
	{/if}
</div>
